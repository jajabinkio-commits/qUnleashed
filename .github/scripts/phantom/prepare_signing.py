"""Validate distribution identity/configuration before importing signing material."""
import base64
import datetime
import os
from pathlib import Path
import plistlib
import subprocess

work = Path(os.environ['PHANTOM_SIGNING_WORK'])
for variable, filename in [('IOS_CERTIFICATE_BASE64', 'certificate.p12'),
                           ('IOS_PROFILE_BASE64', 'profile.mobileprovision')]:
    (work / filename).write_bytes(base64.b64decode(os.environ[variable], validate=True))
profile = plistlib.loads(subprocess.check_output([
    'security', 'cms', '-D', '-i', str(work / 'profile.mobileprovision')]))
team, bundle = os.environ['APPLE_TEAM_ID'], os.environ['PHANTOM_BUNDLE_ID']
entitlements = profile['Entitlements']
if (profile['TeamIdentifier'] != [team]
        or entitlements['application-identifier'] != f'{team}.{bundle}'
        or entitlements.get('get-task-allow', False)
        or 'ProvisionedDevices' in profile
        or profile.get('ProvisionsAllDevices', False)
        or profile['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)):
    raise ValueError('An unexpired App Store distribution profile matching PHANTOM is required')
(work / 'profile.plist').write_bytes(plistlib.dumps(profile))
options = base64.b64decode(os.environ['FIREBASE_OPTIONS_BASE64'], validate=True)
firebase = base64.b64decode(os.environ['IOS_FIREBASE_PLIST_BASE64'], validate=True)
config = plistlib.loads(firebase)
if b'GENERATED PLACEHOLDER' in options or config.get('PHANTOM_COMPILE_ONLY') or config.get('BUNDLE_ID') != bundle:
    raise ValueError('Real Firebase configuration matching PHANTOM is required')
Path('lib/services/notifications/firebase_options.dart').write_bytes(options)
Path('ios/Runner/GoogleService-Info.plist').write_bytes(firebase)
# Build identity is isolated to this disposable checkout, preserving upstream project settings.
p = Path('ios/Runner.xcodeproj/project.pbxproj')
p.write_text(p.read_text().replace('com.darkflippers.qunleashed', bundle))
p = Path('ios/Runner/Info.plist')
info = plistlib.loads(p.read_bytes())
info['CFBundleDisplayName'] = info['CFBundleName'] = 'PHANTOM'
p.write_bytes(plistlib.dumps(info))
(work / 'export.plist').write_bytes(plistlib.dumps({
    'method': 'app-store-connect', 'teamID': team, 'signingStyle': 'manual',
    'signingCertificate': 'Apple Distribution', 'manageAppVersionAndBuildNumber': False,
    'provisioningProfiles': {bundle: profile['UUID']},
}))

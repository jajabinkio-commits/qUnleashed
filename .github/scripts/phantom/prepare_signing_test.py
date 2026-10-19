import base64
import datetime
import os
from pathlib import Path
import plistlib
import runpy
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).with_name('prepare_signing.py').resolve()

class SigningPreflightTest(unittest.TestCase):
    def run_case(self, *, devices=False, stub=False):
        with tempfile.TemporaryDirectory() as directory:
            old = Path.cwd()
            try:
                os.chdir(directory)
                Path('ios/Runner.xcodeproj').mkdir(parents=True)
                Path('ios/Runner').mkdir()
                Path('lib/services/notifications').mkdir(parents=True)
                Path('ios/Runner.xcodeproj/project.pbxproj').write_text('com.darkflippers.qunleashed')
                Path('ios/Runner/Info.plist').write_bytes(plistlib.dumps({}))
                profile = {'UUID': 'test-profile', 'TeamIdentifier': ['ABCDEFGHIJ'],
                           'Entitlements': {'application-identifier': 'ABCDEFGHIJ.org.example.phantom'},
                           'ExpirationDate': datetime.datetime(2099, 1, 1)}
                if devices:
                    profile['ProvisionedDevices'] = ['device']
                config = {'BUNDLE_ID': 'org.example.phantom'}
                if stub:
                    config['PHANTOM_COMPILE_ONLY'] = True
                encoded = lambda value: base64.b64encode(value).decode()
                env = {'PHANTOM_SIGNING_WORK': directory, 'APPLE_TEAM_ID': 'ABCDEFGHIJ',
                       'PHANTOM_BUNDLE_ID': 'org.example.phantom',
                       'IOS_CERTIFICATE_BASE64': encoded(b'fake'), 'IOS_PROFILE_BASE64': encoded(b'fake'),
                       'FIREBASE_OPTIONS_BASE64': encoded(b'fake test options'),
                       'IOS_FIREBASE_PLIST_BASE64': encoded(plistlib.dumps(config))}
                with patch.dict(os.environ, env), patch('subprocess.check_output', return_value=plistlib.dumps(profile)):
                    runpy.run_path(str(SCRIPT))
                export = plistlib.loads(Path('export.plist').read_bytes())
                self.assertEqual(export['provisioningProfiles'], {'org.example.phantom': 'test-profile'})
                self.assertEqual(plistlib.loads(Path('ios/Runner/Info.plist').read_bytes())['CFBundleDisplayName'], 'PHANTOM')
            finally:
                os.chdir(old)

    def test_matching_distribution_profile(self):
        self.run_case()

    def test_reject_device_profile(self):
        with self.assertRaises(ValueError):
            self.run_case(devices=True)

    def test_reject_compile_placeholder(self):
        with self.assertRaises(ValueError):
            self.run_case(stub=True)

if __name__ == '__main__':
    unittest.main()

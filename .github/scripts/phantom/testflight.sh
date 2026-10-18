#!/usr/bin/env bash
# Explicitly invoked on a disposable macOS runner; never use compile stubs.
set -Eeuo pipefail
set +x
required=(APPLE_TEAM_ID PHANTOM_BUNDLE_ID IOS_CERTIFICATE_BASE64 IOS_CERTIFICATE_PASSWORD IOS_PROFILE_BASE64 FIREBASE_OPTIONS_BASE64 IOS_FIREBASE_PLIST_BASE64)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then echo "Missing required setting: $name" >&2; exit 1; fi
done
[[ "$APPLE_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] || { echo 'Invalid Apple team ID' >&2; exit 1; }
[[ "$PHANTOM_BUNDLE_ID" =~ ^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+){2,}$ && "$PHANTOM_BUNDLE_ID" != com.darkflippers.* ]] || { echo 'A separate PHANTOM bundle ID is required' >&2; exit 1; }
[[ "$(uname -s)" == Darwin ]] || { echo 'Requires macOS' >&2; exit 1; }
work="$(mktemp -d)"
keychain="$work/signing.keychain-db"
profile_path=''
cleanup() {
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  [[ -z "$profile_path" ]] || rm -f "$profile_path"
  rm -rf "$work"
  rm -f lib/services/notifications/firebase_options.dart ios/Runner/GoogleService-Info.plist
}
trap cleanup EXIT
export PHANTOM_SIGNING_WORK="$work"
python3 .github/scripts/phantom/prepare_signing.py
profile_uuid="$(/usr/libexec/PlistBuddy -c 'Print UUID' "$work/profile.plist")"
profile_path="$HOME/Library/MobileDevice/Provisioning Profiles/$profile_uuid.mobileprovision"
mkdir -p "$(dirname "$profile_path")"
cp "$work/profile.mobileprovision" "$profile_path"
password="$(openssl rand -hex 24)"
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$work/certificate.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$keychain" >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" "$HOME/Library/Keychains/login.keychain-db"
flutter build ios --release --no-codesign --no-pub --build-number "${GITHUB_RUN_NUMBER:?}"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination generic/platform=iOS -archivePath "$work/PHANTOM.xcarchive" archive PRODUCT_BUNDLE_IDENTIFIER="$PHANTOM_BUNDLE_ID" DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY='Apple Distribution' PROVISIONING_PROFILE_SPECIFIER="$profile_uuid" OTHER_CODE_SIGN_FLAGS="--keychain $keychain"
xcodebuild -exportArchive -archivePath "$work/PHANTOM.xcarchive" -exportOptionsPlist "$work/export.plist" -exportPath build/phantom-testflight
if [[ "${UPLOAD_TESTFLIGHT:-false}" == true ]]; then
  for name in ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY_BASE64; do
    [[ -n "${!name:-}" ]] || { echo "Missing required setting: $name" >&2; exit 1; }
  done
  mkdir -p "$work/private_keys"
  python3 - <<'PY'
import os,base64,pathlib,re
key=os.environ['ASC_KEY_ID']
assert re.fullmatch(r'[A-Z0-9]{10}',key), 'Invalid API key ID'
pathlib.Path(os.environ['PHANTOM_SIGNING_WORK'],'private_keys',f'AuthKey_{key}.p8').write_bytes(base64.b64decode(os.environ['ASC_PRIVATE_KEY_BASE64'],validate=True))
PY
  export API_PRIVATE_KEYS_DIR="$work/private_keys"
  xcrun altool --upload-app --type ios --file build/phantom-testflight/*.ipa --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
fi

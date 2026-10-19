# Install PHANTOM through TestFlight

Status: signing workflow prepared, not executed. No signed IPA or TestFlight invitation exists.

## Owner's next step on iPhone

Install Apple's **Apple Developer** app from the App Store, sign in with your own Apple Account, and follow **Account → Enroll Now** if offered. Membership is normally US$99/year with regional pricing. Complete Apple's identity checks and agreements. ChatGPT Plus and GitHub accounts do not include this membership. Do not send passwords, recovery codes or private signing keys in chat.

After enrolment, the app must be registered in Certificates, Identifiers & Profiles and App Store Connect under that team. Suggested bundle ID `com.jajabinkio.phantom` is a proposal, not registered or guaranteed available. App Store Connect must have a matching PHANTOM app record. Internal TestFlight testers require appropriate App Store Connect access; external testing needs Apple's beta review. Upload processing, compliance questions and invitations are separate from build success.

## Prepared cloud workflow

`.github/workflows/phantom-testflight.yml` is manually dispatched; no PR or push can publish it. It uses a disposable macOS runner, the existing pinned Flutter setup and a separate GitHub environment `phantom-testflight`. Upload defaults off. The signing script rejects mismatched, expired, development/ad-hoc/enterprise profiles and compile-only Firebase configuration. It cleans temporary signing material on exit. No automatic account registration or paid enrolment is attempted.

Configure environment variables `APPLE_TEAM_ID` and `PHANTOM_BUNDLE_ID`. Configure environment secrets through GitHub's secure settings: `IOS_CERTIFICATE_BASE64` (Apple Distribution certificate and private key exported as p12), `IOS_CERTIFICATE_PASSWORD`, `IOS_PROFILE_BASE64` (matching App Store profile), `FIREBASE_OPTIONS_BASE64` (real generated Dart options), and `IOS_FIREBASE_PLIST_BASE64` (matching real iOS Firebase plist). For upload also supply `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_BASE64` (App Store Connect API key with appropriate app access). Base64 is encoding, not encryption: keep these values exclusively in secret storage. Certificate/private-key creation and export may require a trusted Mac or a configured signing service; the workflow does not provide those assets. The user's phone alone does not generate them here.

First run with upload off and review the signed archive and physical test plan. After the distribution build is approved, explicitly run with upload on. Workflow must be present on the default branch to be available normally in Actions; this change is currently on a preparation branch for review. Repository environment protection should restrict use to reviewed release code. Secrets must not be exposed to untrusted changes. No Apple credentials are currently configured, and this workflow has not been tested with real Apple signing.

Build number uses the workflow run number. For a preexisting app record, ensure it exceeds all previously uploaded builds. PHANTOM branding is applied to the disposable build checkout; upstream project identity and GPL source remain intact. App icon, privacy declarations/export compliance, push entitlements if enabling push, physical BLE/voice tests and complete release acceptance still need review. Real Firebase configuration is required by the retained upstream release build; this is separate from the AI provider key entered by the user in the app.

After Apple processes an uploaded build and it is assigned to a tester, install Apple's **TestFlight** app on the iPhone and accept the invitation. TestFlight builds expire after 90 days. An unsigned Runner.app or a ZIP is not an installation route.

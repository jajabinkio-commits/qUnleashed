# Getting PHANTOM onto your iPhone

You do not need to own or operate a Mac to use the eventual app. The app runs on your iPhone and connects directly to the Flipper over Bluetooth.

The app is still being developed. There is no installable PHANTOM link, signed IPA or TestFlight invitation yet. Downloading the source ZIP on your iPhone will not install it.

## What is prepared

A cloud Mac build workflow is now included: `.github/workflows/phantom-ios.yml`. It checks the native iOS app without signing. It has passed actionlint and now runs on pull requests. The first Mac run is in progress; its result must be recorded before claiming native compilation. An unsigned compile artifact is for engineering verification and cannot be installed on your phone.

## What still requires your participation

1. Establish an Apple Developer/distribution account when the app is ready for signed testing. You told us membership is not yet known/established. Any Apple sign-in, enrollment and account approval must be performed by you through Apple's own interface. Do not paste passwords, certificates or API keys into chat.
2. Configure the cloud build under an authorized repository/build account and a PHANTOM app/bundle identity. The repository is jajabinkio-commits/qUnleashed, draft PR #1; a macos-15 GitHub runner is compiling the first unsigned build. Engineering should prepare the concrete configuration before requesting account access or running paid services.
3. Once signing is available, create and verify the signed build, upload through the chosen Apple-supported route, then send you the actual installation link. No TestFlight upload has occurred.
4. On your iPhone, test pairing and controls with your actual Flipper. We can supply the checklist and interpret results, but simulated tests cannot observe your Bluetooth hardware.
5. For AI, enter your own OpenRouter key **inside the finished app**; the iPhone Keychain stores it. Public model discovery requires no key, but private chat requires an authorized account with available service/credit. Do not send the key in this conversation. Erasing the app’s conversation clears its local memory; retention by OpenRouter/model providers follows their own policies.

Normal iPhone use will not require an always-on computer. USB terminal and complete DFU repair remain separate bridge-only functions.

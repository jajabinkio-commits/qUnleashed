# PHANTOM physical test log

No hardware tests performed. Device IDs, firmware versions and Apple signing state must not be invented.

## M1 operator procedure (macOS + physical iPhone + owned Flipper)

1. Record iPhone model/iOS, Flipper device identifier, current firmware/build/protocol and source revision. Preserve installed firmware/apps and user files. Record BLE permissions and pairing expectations.
2. Build using pinned Flutter 3.47.1, recursive submodules, real project configuration and a compatible installed Xcode SDK. Set an authorized PHANTOM bundle/team identity; do not reuse upstream signing credentials. Record exact Xcode version and whether build is signed. See release blockers before restoring service configuration.
3. Open Device tab; discover and connect using retained qUnleashed controls. Verify actual battery, firmware and storage; toggle Bluetooth and reconnect. Test T01/T02/T04.
4. Open **PHANTOM inspection**; read status. Compare values against the manual dashboard/device. Disable internet and omit AI keys, repeat. Unsupported power/storage must remain explicitly unknown/unsupported. Test T04/T06/T28 portions only.
5. While inspection runs, press **Stop inspection**; then background app. No later reading should be accepted. The one in-flight RPC may drain; verify no follow-on requests. Repeat switching two Flippers; no mixed status. Test T03/T39 portions.
6. Open retained Remote screen: observe visible changes, all six short and long buttons, PNG/GIF, and ordered rapid input. Record actual frames and firmware without assuming mock coverage proves T07–T11.
7. In retained Files, list accessible `/ext` and `/int`; explicitly choose a harmless new filename, transfer a known text sample and verify content/checksum. Test disconnect recovery without overwriting valuable files. Hardware T13–T17 remain unpassed by read-path unit tests.
8. Use catalog metadata to install/launch a harmless compatible app only with explicit operator approval. Keep known-working apps. Record actual compatibility checks; do not align firmware version names.
9. CLI and full DFU are bridge-required, not iPhone BLE. No bridge implemented in cycle 01; do not attempt recovery under these instructions.

Each record requires: Test ID; platform/transport; source, firmware and host version; expected result; actual result; simulated vs physical; PASS/FAIL/BLOCKED/UNVERIFIED; artifact path. Use this template:

| ID | Platform/transport | Firmware/host/source | Expected | Actual | Physical/simulated | Status | Artifact |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T01 | physical iPhone/BLE | not supplied | Actual Flipper discovered | Not run: hardware unavailable | Physical | BLOCKED | none |

All 50 current statuses are enumerated in `ACCEPTANCE_STATUS.md`. No hardware acceptance gate is marked PASS.

## Cycle 02 additional procedures (not run)

After a real signed build exists, record iOS/Flipper/source versions and test:

- First install and legacy preference migration: diagnostics/replay/notification switches off, no permission prompts or Firebase initialization before opt-in. Test denied notification permission, fresh consent, revocation and old native token cleanup; verify no unexpected replay recorder starts.
- Save/read/update/erase a test OpenRouter credential through the real iPhone Keychain; ensure no preferences/plaintext copy or iCloud synchronization and verify behavior when locked. Never record the key in screenshots or logs.
- Public model discovery, approved live provider round-trip, offline/provider failure while manual BLE controls continue. Record provider/model/usage; use an explicitly approved account budget. No hard dollar-cap enforcement is claimed by this slice.
- Default chat sends no device data. Each status-consented Send resets the switch off. Compare returned battery/storage to device observation; switch Flippers during a tool read; background/STOP must prevent later tool steps and late answers.
- Read-only AI must reject every mutation, RF, CLI, firmware or invented tool. File/screen/voice inputs are absent from this slice; their acceptance remains pending.

All remain BLOCKED/UNVERIFIED until performed on hardware. The manual Mac workflow has not executed and its unsigned artifact would not itself qualify installation/signing acceptance.

## Cycle 06 screen interpretation procedure (not run)

On a signed build and owned Flipper: verify Explain screen uses the displayed recent frame in each orientation, defaults sharing off and sends nothing on entry; compare visible screenshot pixels to the selected Flipper. Confirm disconnect/device change clears capture, GIF recording disables AI entry and returning from preview resumes streaming. Test provider failure/back/STOP/background with no button or mutation action and no unconsented resend. Enter a test provider key only through the app, approve one bounded live request under an explicit account budget and compare interpretation to the physical screen, marking uncertain OCR as inference. Verify opt-in replay masks both AI pages on a real iPhone. None of these physical/live-provider gates is passed by simulation or compilation.

## Cycle 07 on-device dictation procedure (not run)

On a signed PHANTOM build, record iPhone/iOS, locale, on-device model availability and source SHA. Verify startup/typed-only chat never activates the microphone or asks for permission. Tap Dictate explicitly; test granted, denied and unavailable speech/microphone states and confirm typing remains possible. Test the permission dialog's inactive state separately from actual backgrounding. Verify the microphone indicator stops after Finish, STOP, 20-second capture timer, app background and audio interruption; verify late results never replace a new draft. Verify recorded audio is not written to app storage and there is no recognition-server fallback when local recognition is unavailable. Review/edit transcript, then explicitly Send under the same model/tool consent; no utterance alone may send AI traffic or act on the Flipper. Erase must clear transcript/draft. Test cancellation-channel failure indication and input/audio route changes on hardware. Confirm sensitive-page replay masking if opted in. None of these native/runtime/privacy checks is passed by the mocked channel/UI tests or a successful compile.

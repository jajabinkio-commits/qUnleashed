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

# M0 upstream audit — 18 October 2026

## Directly inspected
- Connected fork: `jajabinkio-commits/qUnleashed`.
- Main commit at audit: `90ca7621cdaf56c996e2fddacf126fa71d64d6f5`.
- Main tree: `bed57d202aefc247378f92a7d7957743641ceee2`.
- Git submodule `lib/modules/flipperlib` points to
  `DarkFlippers/dart-flipperlib` SHA
  `627f35d7c1e798fe8265a3fda38dfc9f8e219ee6`.
- `pubspec.yaml`: Flutter >=3.47.1 / SDK ^3.13.1; vendored flipperlib
  through local path, `universal_ble` and `flutter_test`.
- `lib/main.dart`: one `FlipperOneClient().get()` in shared core, injected
  into `QUnleashedApp`.
- `lib/pages/devices/controllers/device.dart`: injectable
  `DeviceController` extends ChangeNotifier and exposes
  `connectionState`, `device`, `info`, `firmwareVersion`,
  `deviceInfoConnected`, `synchronize()`.
- `test/firmware_fixture.dart`: existing `FakeFlipperClient` and
  `mountedDevice()` test seam; no need to mock a guessed BLE API.
- `README.md`: iOS 15+ over BLE; iOS USB CLI unavailable, desktop/Android
  USB access separate; remote, archive, app catalogue and update workflows.
- `LICENSE` exists and upstream README marks GPL; preserve notices.
- Existing workflow `.github/workflows/ci.yml` exists; inspect it before
  changing build rules.

## Constraints and unknowns
- This run could inspect GitHub via connector but container git clone failed
  (no DNS access to github.com). Flutter and Dart executables were absent.
- No actual paired Flipper or signed iOS build environment was available.
- Physical capabilities/firmware compatibility remain unverified.
- Submodule source was inspected from public repository files; pin verified
  gitlink before adapting new low-level RPC methods.
- No old firmware, submodule pointers, BLE transport or existing CI files
  changed in this milestone.


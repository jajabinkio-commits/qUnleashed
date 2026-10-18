# PHANTOM acceptance checklist

## M0/M1a — current PR
- [ ] Baseline source, submodule gitlink and dependencies inspected.
- [ ] `flutter pub get --enforce-lockfile` passes on supported SDK.
- [ ] `flutter analyze` passes with no new diagnostics.
- [ ] Existing `test/device_controller_client_test.dart` passes.
- [ ] New disconnected snapshot contains no fabricated device/firmware.
- [ ] Connection event with no actual selected device is not treated as valid.
- [ ] Capability map reports unverified features honestly and is immutable.
- [ ] Unconnected refresh rejects without touching transport.
- [ ] Snapshot stream emits initial and controller changes, cancels listener.
- [ ] AI action status returns snapshot without claiming a new RPC read.
- [ ] Unknown action and unexpected arguments reject.
- [ ] All existing tests continue passing.

## M1b/M2
- [ ] Real iPhone connects to physical Flipper with stable BLE session.
- [ ] PHANTOM status follows active Flipper through disconnect/reconnect.
- [ ] Screen and buttons function with bounded latency.
- [ ] Screenshot/GIF recording succeeds and stops cleanly.
- [ ] Changing active device does not retarget an ongoing session.

## M3/M4
- [ ] Read-only file listing and data transfer are validated on device.
- [ ] All mutation paths require user consent and validate paths.
- [ ] Model-proposed operations go through one deterministic policy.
- [ ] Unknown tools, prompt-injected content and invalid arguments reject.
- [ ] API credentials are stored in Keychain; none appear in logs.
- [ ] Model failure never reports unobserved hardware success.

## M5/M6/M7
- [ ] Voice and Shortcuts honor the same permission and policy checks.
- [ ] STOP prevents queued actions and stops active supported emulations.
- [ ] iOS background limitations are documented/tested.
- [ ] Optional USB bridge uses authenticated scoped sessions.
- [ ] Host CLI is distinguished from an unrestricted OS shell.
- [ ] DFU requires out-of-band confirmation and validated firmware image.
- [ ] Signed iOS build and physical regression matrix pass.

Every unchecked item is pending. No simulated test counts as a real device test.


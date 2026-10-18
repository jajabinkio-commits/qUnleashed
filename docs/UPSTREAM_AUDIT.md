# PHANTOM upstream audit — M0 / first M1 slice

Audit date: 2026-10-14. All claims below are source inspection or simulated verification unless explicitly labelled otherwise. No physical Flipper or iPhone is attached.

## Source identity

- Base: https://github.com/DarkFlippers/qUnleashed, commit `975e3ebd810091a31212abb2998ffb7628363069`, version `0.17.0`.
- Local feature branch: `phantom/m0-m1`; original history and `origin` retained. No remote repository was created or pushed.
- Recursive checkout succeeded. Exact pins: [revision log](evidence/upstream-revisions.log).
- flipperlib `1.0.1`: `627f35d7c1e798fe8265a3fda38dfc9f8e219ee6`.
- dartufbt `0.1.2`: `c66737ce0cf96f76796b333f04705d56de0a247c`.
- Embedded protobuf (DarkFlippers fork): `dd27b64a9f19e598dc428e15c3397df1e4dc497c`.
- Official protobuf reference: https://github.com/flipperdevices/flipperzero-protobuf at `1c84fa48919cbb71d1cc65236fc0ee36740e24c6`.
- Official iOS reference: https://github.com/flipperdevices/Flipper-iOS-App at `2c1c8531953110631ca471251280a1602d118011`.

## Build baseline

Verified: Linux x86_64, Flutter `3.47.1` / Dart `3.13.1`, SDK source `6655482ec06e547f90abf8ae7590466f4415978d`. This matches upstream `.github/actions/setup-flutter/action.yml` and `pubspec.yaml`. Installed under `/workspace/toolchains/flutter`, outside application source. Hosted dependency versions and submodule pins were preserved; `flutter pub get --enforce-lockfile` passed without lockfile edits.

The initial SDK bootstrap and analyzer failed because their default cache locations were read-only. Setting `PUB_CACHE`, `XDG_CONFIG_HOME`, and the analyzer's documented `ANALYZER_STATE_LOCATION_OVERRIDE` to writable workspace locations resolved them. The first isolated test launch failed because its local test server required network-enabled sandbox execution; the retry passed. These were environment failures, not BLE results.

Baseline verification before application changes:

- Format: 536 Dart files checked, no changes.
- Analyzer: initial exit 255 due to read-only `.dartServer`; retry **no issues found**.
- Flutter unit/widget suite: **1,851 passed, 5 skipped**, exit 0. No skipped test is counted as hardware evidence.
- A generated, gitignored Firebase placeholder was created with upstream `.github/scripts/stub_firebase_config.sh`, exactly as CI does. It throws when Firebase is requested; it is not production configuration.
- Xcode, an Apple signing identity, physical iPhone and Flipper hardware are unavailable. A signed iOS build is BLOCKED.

## Actual stack and interfaces

| Area | Verified source and interfaces | Treatment |
| --- | --- | --- |
| Discovery/pairing | `lib/services/connection/link_service.dart`, `known_devices.dart`; `FlipperClient.refreshDevices`, `connect`, `activate`, `connectionStream`, `sessionsStream` | Retained, physical pairing unverified |
| BLE transport | `lib/modules/flipperlib/lib/src/transport/ble/{gatt,ios,link,platform}.dart`; `universal_ble` 2.3.x from lockfile | No protocol changes |
| RPC/session queue | `lib/modules/flipperlib/lib/src/{client/client,session/session,session/protocol,session/queue}.dart` | Preserve priority, framing, flow control, timeout and binding |
| Status | `client/api/system.dart`: `deviceInfo`, `powerInfo`, `protobufVersion`; `client/api/storage.dart`: `storageInfo`; `DeviceInfoWatchService` and `DeviceController` | Wrapped by new read-only `FlipperGateway` |
| Remote | `lib/pages/tools/remote/desktop/session.dart`, page, frame decoder, screenshot encoder and GIF code; `client/api/gui.dart` | Retained, no duplicate remote engine |
| Files/archive | `lib/pages/archive/browser/`, `lib/services/archive/storage.dart`, `client/api/storage.dart` | Retained; validated read-only listing added |
| Apps | `lib/pages/apps/data/{catalog_api,catalog_context,install_engine,apps_backend}.dart`; manager/catalog pages; `client/api/app.dart` | Retained, ABI/device compatibility requires hardware evidence |
| Firmware | `lib/pages/devices/firmware/{installer,source,matcher,directory,repository}.dart` | Retained; no flashing or firmware replacement |
| Toolbox | `lib/pages/tools/{paint,infrared,plotter,mifare,subghz}/`; archive map | Retained; advanced functions not added to AI tools |
| USB CLI/DFU | `client/api/usb.dart`, transport USB, `src/dfu/`; CLI excluded by `Platform.isIOS` in tools overview | Explicit bridge-required capabilities in PHANTOM |

The library API uses statically resolved extension methods on `FlipperClient`. New tests subclass the real client and replace `callRpcFrames`, exercising real extension methods and `callRpc` response selection. No extension method on a fake is substituted for the real body.

Session detail: `bindCurrentSession().run` binds unattended requests to one link. **Foreground priority bypasses that binding**, so the gateway uses `unattended` for each multi-request inspection. `DeviceToken`, binding liveness and connection-event invalidation prevent mixed-device observations. The shared client is injected; no new singleton or BLE connection is created.

## Official cross-checks

Official `gui.proto` exactly matches the embedded source at the audited pins ([empty diff](evidence/official-gui-diff.log)). Keys are UP/DOWN/RIGHT/LEFT/OK/BACK, with PRESS/RELEASE/SHORT/LONG/REPEAT and orientation enums. This observation does not prove physical button behavior.

Official iOS `Flipper/Packages/Peripheral/Sources/Bluetooth/Platform/CBUUID.swift` serial service and receive/transmit characteristics match vendored `transport/ble/gatt.dart`: `8fe5b3d5-2e7f-4a98-2a48-7acc60fe0000`, `19ed82ae-ed21-4c9d-4145-228e61fe0000`, `19ed82ae-ed21-4c9d-4145-228e62fe0000`. Official advertised discovery identifiers are separate; PHANTOM keeps the existing discovery implementation.

Embedded storage protobuf adds range-read fields absent from official definitions ([diff](evidence/official-storage-diff.log)). Preserve existing compatibility handling and label extensions; do not regenerate bindings against official HEAD and erase working additions. This slice uses only common status/list fields. Reported protocol numbers never automatically grant unrelated capabilities.

## iOS configuration

Source targets iOS 15.0 and Swift 5.0; CocoaPods frameworks, Swift Package Manager disabled. `ios/Runner/Info.plist` contains Bluetooth permission descriptions, `bluetooth-central` background mode, location, photo-library and Files permissions. These declarations are not proof of successful device behavior or continuous background execution. Microphone, speech recognition, App Intents and Keychain provider integration remain future work. Original bundle identity and display name remain qUnleashed during this foundational slice; PHANTOM release identity/signing requires a separate configured build.

## License/dependency/privacy findings

Root LICENSE, flipperlib, dartufbt and NFC-tools are GPL-3.0 texts. Extensions and irondash retain MIT notices. Official iOS is MIT; no Swift source was copied. All source notices and submodule pins are retained. Full hosted/native dependency redistribution review, source-delivery process, and Apple distribution compatibility remain release work; this inspection is not a completed legal clearance.

`pubspec.yaml` includes Firebase messaging/core and Sentry `9.30.1`. **Upstream `DiagnosticsSettings` defaults log sharing and replay to true**. `PushService.start` initializes Firebase and asks for permission at startup; release push subscriptions default to enabled. This conflicts with PHANTOM's default privacy requirements. No real DSN/Firebase credentials exist in this workspace. Before adding provider keys or shipping, implement opt-in diagnostics/replay, consent migration and opt-in push initialization with tests. Do not restore upstream service credentials into PHANTOM releases.

Reliability finding: the existing `storageWriteChunked` reconnect path retries an upload. PHANTOM does not expose mutations or flashing to AI in this slice. Before M3, inspect that retry behavior and add state/read-back verification and explicit policy to avoid blind repeated mutations. `/int` may alias SD storage in current firmware; this slice reports only `/ext` capacity and never labels it as internal-chip capacity.

## Unknowns

Actual device/firmware revisions, physical BLE pairing, radio behavior, live framebuffer/buttons, file-transfer integrity, app compatibility, DFU host behavior, external module APIs and signed iOS distribution remain unknown. M1's physical gate is not passed. No API provider call, firmware/app replacement, RF operation or recovery attempt occurred.

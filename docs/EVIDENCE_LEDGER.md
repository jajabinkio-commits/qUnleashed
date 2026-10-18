# Evidence ledger — PHANTOM

| Assertion | Classification | Evidence | Next validation |
|---|---|---|---|
| Fork exists with write access | VERIFIED | GitHub repository and authenticated collaborator permission | inspect branch/PR |
| Baseline main SHA 90ca7621 | VERIFIED | GitHub branch API 2026-10-18 | compare before merging |
| Controller supports injected FlipperClient | VERIFIED SOURCE | `lib/pages/devices/controllers/device.dart` | run baseline mock tests |
| Fake client fixture is reusable | VERIFIED SOURCE | `test/firmware_fixture.dart` | execute Flutter tests |
| qUnleashed has iOS BLE path | VERIFIED SOURCE CLAIM | `README.md`, `pubspec.yaml` | physical iPhone/Flipper test |
| Gateway read-only Dart code compiles | UNVERIFIED | new code inspected manually | run Flutter analyzer/test |
| Physical Flipper screen and remote works via PHANTOM | NOT TESTED | no hardware session | paired iPhone test |
| OpenRouter keys/AI tools integrated | NOT IMPLEMENTED | no provider code | M4 |
| Signed iPhone IPA exists | NOT IMPLEMENTED | no signing environment | M7 |
| Optional secure USB host bridge works | NOT IMPLEMENTED | no bridge | M6 |

Do not convert source claims or mock successes to physical test evidence.


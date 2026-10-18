# PHANTOM implementation cycle 01

**Outcome:** pinned/audited qUnleashed baseline plus an executable first M1 read-only component. Full M1 and M2–M7 are not complete. No signed IPA or physical hardware acceptance is claimed.

## Implemented

- Read every supplied specification file before code; place mandatory AGENTS.md in root, plan/acceptance/start prompt in docs, maintain all 31 capabilities and all 50 test statuses. Preserve the original supplied CSV as SPEC_FEATURE_MATRIX.csv.
- Recursive qUnleashed checkout at `975e3ebd810091a31212abb2998ffb7628363069`; feature branch `phantom/m0-m1`. Original git history, licenses, upstream remote, lockfile and six recursive submodule pins retained.
- Inspect real Dart/Flutter/iOS dependencies, queue/session semantics, manual features, official native BLE and pinned official protobuf. Record facts, privacy/retry issues and unknowns.
- Implement immutable DeviceSnapshot/CapabilityReport/file observations and a read-only DeviceGateway adapter over actual existing FlipperClient extension methods.
- Read device information, power, protocol and external storage, preserving missing/error readings. Successful response bodies establish only their exact observed capabilities; timeouts or unavailable data stay unverified. No firmware-name inference or mutation entry point.
- Expose validated `/ext` and `/int` read-only listings. Reject noncanonical paths, traversal, percent aliases, backslashes/control characters and oversized paths before RPC.
- Bind inspection to the existing session with unattended priority, detect switches/reconnects, bound each request, and discard cancelled/stale results. STOP prevents subsequent inspection requests; the already-sent request drains or times out. No auto-retries added.
- Add Device-tab **PHANTOM inspection** route, with local manual status/capability display, STOP and background cancellation. No provider/key required. Closing the route leaves the shared BLE client intact. Retained screens and transport are unchanged.
- Add 16 RPC-boundary simulated tests and four Flutter widget tests.

## Verification results

All logs are retained in `docs/evidence/`. Commands ran with the pinned SDK and workspace-owned caches; Flutter tests used socket-enabled sandbox execution.

| Command | Observed result | Meaning |
| --- | --- | --- |
| `flutter pub get --enforce-lockfile` | PASS, exit 0 | Upstream hosted versions/lockfile preserved |
| Baseline `.github/scripts/check_format.sh` | PASS, 536 files | No upstream formatting edits |
| Baseline `flutter analyze --no-pub` | First exit 255 cache error; retry PASS/no issues | Read-only-home environment repaired using documented analyzer cache override |
| Baseline `flutter test --no-pub --reporter expanded` | PASS: 1,851 / 5 skipped | Upstream simulated baseline |
| `flutter test ... test/phantom_gateway_test.dart test/phantom_inspection_page_test.dart` | PASS: 20 | Real API extensions + fake frames; simulated UI |
| Final `.github/scripts/check_format.sh` | PASS, exit 0 | New and retained Dart formatted |
| Final `flutter analyze --no-pub` | PASS: no issues, exit 0 | Initial new-code style/import issues corrected |
| Final `flutter test --no-pub --reporter expanded --test-randomize-ordering-seed=20261014` | PASS: **1,871 / 5 skipped**, exit 0 | Full application regression including new tests |
| flipperlib `flutter pub get` and `flutter test --no-pub --reporter expanded` | PASS: **138**, exit 0 | Pinned library's own simulated suite, no source edits |
| `flutter test --no-pub --dart-define=QLOG=false --dart-define=QLOG_EXPECT_QUIET=true test/logging_kept_test.dart test/kept_sink_test.dart` | PASS: **51**, exit 0 | Upstream CI's quiet logging configuration |
| `flutter build bundle --no-pub` | BLOCKED: Android SDK absent | Default target unavailable |
| `flutter build bundle --target-platform=linux-x64 --no-pub` | PASS, exit 0; `build/flutter_assets/kernel_blob.bin` produced | Actual Dart/kernel/assets compilation; not native Linux or iOS validation |
| `flutter build ios --no-codesign --no-pub` | BLOCKED on Linux: iOS options unavailable, exit 64 | No Xcode/native iOS compile, signing or IPA |
| Physical BLE/Flipper / signed iPhone test | BLOCKED, not run | No physical hardware, macOS or signing configured |

Failed attempts are retained: initial SDK/analyzer cache issues and test-server socket restriction were environment issues; an intermediate split-test missing import and analyzer style issues were corrected. Final analyzer and all final executed suites pass. Five existing tests remain skipped because optional uFBT/native/build-server prerequisites are absent; skips are not accepted as passing tests.

## Remaining limits and gates

- M1's physical pair → live screen → buttons → files → harmless compatible app gate remains BLOCKED. Simulated tests never qualify it.
- M2 provider chat/voice/vision/Keychain/read-only tool loop, M3 supervised actions/policy/audit/automations, M4 Shortcuts/advanced iOS, M5 authenticated bridge, M6 modules and M7 release remain pending.
- Gateway has no arbitrary AI execution path or mutation/firmware API. Its STOP only cancels this inspection, not existing unrelated qUnleashed tasks. It cannot physically retract an in-flight read.
- Native iOS plugin/link behavior and signing are unverified. Firebase CI placeholder is local/gitignored; production push is unavailable. No provider credentials exist.
- Upstream diagnostics/replay default ON and startup Firebase behavior require privacy remediation before AI secrets/release. Existing upload reconnect retries require verification before AI mutations.
- New English strings are supplied; Russian/Ukrainian have 19 untranslated strings each (three baseline plus 16 new). English fallback generated; no translated ARB was manually changed.
- Original app display/bundle/release identity remains qUnleashed during the baseline slice. PHANTOM branding/signing and full derivative distribution/third-party license review are pending.

## Next executable task

Implement opt-in diagnostics/replay/push and consent migration with fail-closed preference-loading/redaction tests. In parallel with available hardware, execute HARDWARE_TEST_LOG.md's M1 procedure on the recorded iPhone/Flipper without firmware or app replacements. Do not mark M1 complete or advance its physical gate based on these mock results.

## Exact added/modified files

The following list includes supplied docs, implementation, tests and raw verification artifacts. Existing licenses, lockfile, protocol sources and submodules have no source changes. SDK/caches/build outputs and generated Firebase/localization files are intentionally outside this source change.

- `AGENTS.md`
- `PHANTOM_README.md`
- `docs/ACCEPTANCE_STATUS.md`
- `docs/ACCEPTANCE_TESTS.md`
- `docs/CODEX_START_PROMPT.txt`
- `docs/DECISIONS.md`
- `docs/FEATURE_MATRIX.csv`
- `docs/FEATURE_MATRIX.md`
- `docs/HARDWARE_TEST_LOG.md`
- `docs/IMPLEMENTATION_CYCLE_01.md`
- `docs/MASTER_PLAN.md`
- `docs/RELEASE_READINESS.md`
- `docs/SPEC_FEATURE_MATRIX.csv`
- `docs/SPEC_README.md`
- `docs/UPSTREAM_AUDIT.md`
- `docs/evidence-ledger.md`
- `docs/evidence/baseline-analyze-retry.log`
- `docs/evidence/baseline-analyze.log`
- `docs/evidence/baseline-format.log`
- `docs/evidence/baseline-pub-get.log`
- `docs/evidence/baseline-test.log`
- `docs/evidence/flipperlib-pub-get.log`
- `docs/evidence/flipperlib-test.log`
- `docs/evidence/flutter-version.log`
- `docs/evidence/m1-analyze-final.log`
- `docs/evidence/m1-analyze.log`
- `docs/evidence/m1-build-bundle-linux.log`
- `docs/evidence/m1-build-bundle.log`
- `docs/evidence/m1-format.log`
- `docs/evidence/m1-gateway-test-retry.log`
- `docs/evidence/m1-gateway-test.log`
- `docs/evidence/m1-ios-build.log`
- `docs/evidence/m1-l10n.log`
- `docs/evidence/m1-quiet-test.log`
- `docs/evidence/m1-regression-test.log`
- `docs/evidence/m1-slice-test.log`
- `docs/evidence/m1-targeted-test.log`
- `docs/evidence/official-gui-diff.log`
- `docs/evidence/official-storage-diff.log`
- `docs/evidence/upstream-revisions.log`
- `lib/app/routes.dart`
- `lib/components/navigation.dart`
- `lib/pages/devices/page.dart`
- `lib/phantom/core/device_snapshot.dart`
- `lib/phantom/device/device_gateway.dart`
- `lib/phantom/device/flipper_gateway.dart`
- `lib/phantom/features/devices/inspection_page.dart`
- `test/phantom_fakes.dart`
- `test/phantom_gateway_test.dart`
- `test/phantom_inspection_page_test.dart`
- `translations/app_en.arb`

# PHANTOM evidence ledger

2026-10-14, Linux x86_64. Classification is deliberately separate from acceptance status.

| Evidence | Classification | Observation | Artifact |
| --- | --- | --- | --- |
| Entire supplied ZIP | VERIFIED FACT | Six files read before code; AGENTS in root, other supplied files in docs; CSV mirrored with all 31 rows | `MASTER_PLAN.md`, `SPEC_README.md`, `FEATURE_MATRIX.csv` |
| Recursive upstream checkout | VERIFIED FACT | Base `975e3ebd810091a31212abb2998ffb7628363069`; original history retained | `UPSTREAM_AUDIT.md`, `evidence/upstream-revisions.log` |
| Flutter SDK | VERIFIED FACT | Flutter 3.47.1, Dart 3.13.1 | `evidence/flutter-version.log` |
| Dependency resolution | PASS, host | Enforced upstream lockfile, no dependency edits | `evidence/baseline-pub-get.log` |
| Baseline format | PASS, host | 536 files, zero formatting changes | `evidence/baseline-format.log` |
| Baseline analyze | PASS after environment repair | Initial cache error; retry no issues | `evidence/baseline-analyze.log`, `evidence/baseline-analyze-retry.log` |
| Baseline tests | PASS, SIMULATED | 1,851 passed, 5 skipped | `evidence/baseline-test.log` |
| Official GUI protocol | VERIFIED FACT, source | Exact match with embedded GUI definitions | `evidence/official-gui-diff.log` |
| Official storage protocol | VERIFIED FACT, source | Vendored range-read extension differs; common fields retained | `evidence/official-storage-diff.log` |
| Official native iOS BLE | VERIFIED FACT, source | Audited UUIDs match; no physical interoperability test | `UPSTREAM_AUDIT.md` |
| First gateway tests | PASS, SIMULATED | Original 16 gateway tests pass | `evidence/m1-gateway-test-retry.log` |
| Combined first slice | PASS, SIMULATED | 16 gateway + 4 widget tests pass after missing-import correction | `evidence/m1-slice-test.log` |
| Intermediate verification failures | FAIL, corrected | Local socket restriction, missing test import, analyzer style issues | `evidence/m1-gateway-test.log`, `evidence/m1-targeted-test.log`, `evidence/m1-analyze.log` |
| Pinned flipperlib own tests | PASS, SIMULATED | 138 transport/queue/session/storage/DFU parser tests passed | `evidence/flipperlib-test.log` |
| Final regression | PASS, SIMULATED | 1,871 passed / 5 skipped; seed 20261014 | `evidence/m1-regression-test.log` |
| Final analyze / format | PASS, host | No issues; 543 Dart files formatted | `evidence/m1-analyze-final.log`, `evidence/m1-format.log` |
| Quiet logging configuration | PASS, SIMULATED | 51 passed with QLOG=false / QLOG_EXPECT_QUIET=true | `evidence/m1-quiet-test.log` |
| Flutter bundle | PASS, Linux target | Dart kernel/assets compiled, not a native executable or iOS build | `evidence/m1-build-bundle-linux.log` |
| iOS BLE behavior | UNKNOWN / BLOCKED | No iPhone or Flipper attached | `HARDWARE_TEST_LOG.md` |
| Signing and release | UNKNOWN / BLOCKED | No macOS/Xcode/signing or installable IPA | `RELEASE_READINESS.md` |
| Provider/AI/bridge/extensions | UNKNOWN / NOT IMPLEMENTED | No provider calls, command controller, bridge or module adapter | `FEATURE_MATRIX.md` |

Final cycle results are recorded in `IMPLEMENTATION_CYCLE_01.md` and final evidence logs. Simulated test counts never substitute for any of T01–T50's physical acceptance records.

## Cycle 02 — 2026-10-15

User confirmed iPhone-only operation and asked engineering to carry out implementation. Apple Developer membership remains not established. Code remains based on the same upstream/submodule pins; no hosted dependency or lockfile changes.

| Evidence | Classification | Observed result | Artifact |
| --- | --- | --- | --- |
| Privacy defaults/migration | PASS, SIMULATED | 12 new preference/SDK boundary tests; legacy values ignored, unreadable preferences fail closed, no Firebase initialization before consent | `evidence/cycle02-privacy-test.log`, `test/phantom_privacy_test.dart` |
| Reporting lifecycle compatibility | PASS, SIMULATED | Explicit opt-in fixtures; loaded replay choice captured before SDK startup, so a startup replay change is not lost | `evidence/cycle02-privacy-test.log` |
| Read-only agent/provider | PASS, SIMULATED | 19 tests: consent, no writes, batch validation, budgets, device switching, STOP, minimization, prompt-key rejection, echoed-key redaction | `evidence/cycle02-ai-final.log` |
| AI chat screen | PASS, SIMULATED | Four widget tests: no startup request, obscured key cleared after save, model/send, erase, per-send consent reset and background cancellation | `evidence/cycle02-ai-ui-final.log` |
| Combined targeted verification | PASS, SIMULATED | 43 tests including shutdown behavior after privacy change | `evidence/cycle02-final-focused.log` |
| OpenRouter wire specification | VERIFIED FACT, public schema | Fixed HTTPS base/chat/models paths, bearer authentication, max_completion_tokens, function-name rule; underscores mapped to internal dotted tool names | `evidence/cycle02-openrouter-schema.log` |
| Public model catalog | VERIFIED FACT, public service | 462 entries, 393 advertise tools at time of check; no key or paid inference used | `evidence/cycle02-openrouter-schema.log` |
| Native credentials | SOURCE IMPLEMENTED / NATIVE UNVERIFIED | iOS Security.framework Keychain, fixed account/service, WhenUnlockedThisDeviceOnly, non-sync; Dart channel tested with mocks | `ios/Runner/AppDelegate.swift`, `test/phantom_ai_test.dart` |
| Native push flags | SOURCE CHECK | iOS plist / Android manifest parse; auto-init disabled in source | `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml` |
| Cloud Mac workflow | LINT PASS / NOT EXECUTED | Manual unsigned compile job prepared; no Apple credentials, remote repository/runner or publishing used | `evidence/cycle02-workflow-lint.log`, `.github/workflows/phantom-ios.yml` |
| Intermediate failures | FAIL, corrected / superseded | Initial privacy fixtures, replay-start race and invalid test lifecycle transitions corrected. First full run included four failures: two old shutdown assumptions and two new provider tests added while source was still changing; that run was not a consistent source snapshot, and the final frozen-source rerun is authoritative | `evidence/cycle02-privacy-initial.log`, `evidence/cycle02-chat-ui-test.log`, `evidence/cycle02-regression-test.log` |

Final full-regression/build results are recorded in IMPLEMENTATION_CYCLE_02.md. No physical BLE, native iOS Keychain/APNs/replay, signed build, private/paid provider call, voice, screen interpretation or supervised write action is marked verified.

Final observed cycle 02 results: **1,906 application tests passed / five prerequisite-dependent tests skipped** (seed 20261015); analyzer no issues; format checked 551 files unchanged; quiet logging 51 passed; final Linux-target Dart kernel/assets bundle compiled. Logs: `cycle02-regression-final.log`, `cycle02-analyze-final.log`, `cycle02-format-final.log`, `cycle02-quiet-test.log`, `cycle02-bundle-final.log`. No native iOS, private inference or physical gate was passed.

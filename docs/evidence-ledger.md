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

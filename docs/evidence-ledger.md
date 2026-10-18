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

## Cycle 03 — 2026-10-15

- Earlier PHANTOM-name checks returned 404. The user then supplied `jajabinkio-commits/qUnleashed`, which exists publicly (main). Connected account `jssanderson93-svg` has pull=true, push=false, admin=false. Collaborator-permission query returned HTTP 403, integration restriction. No remote mutations occurred; account authorization remains required.
- Local AI observation separation: new `AgentObservation` and `ObservationCard` use actual controller/gateway results, independent of model narrative. Unknown values are not converted into fabricated readings. Observations are immutable snapshots bound to a request and local chat turn.
- Focused simulated checks: **31 passed** (`evidence/cycle03-focused-final.log`), covering contradictory AI narrative versus observed battery, invented model readings, provider-failure evidence, erase, per-request evidence boundaries, invalid battery data, unknown values and hidden device identifiers.
- Final frozen-source verification: 1,914 tests passed / five skipped; analyzer no issues; format checked 554 files unchanged; Linux-target Dart kernel/assets bundle exit 0. Results/log paths are recorded in IMPLEMENTATION_CYCLE_03.md. Native/signing/hardware/private-provider gates remain unverified.

## Cycle 04 — 2026-10-16

Owning GitHub profile connected; metadata push=true but actual git push and connector branch creation both denied HTTP 403. Actions settings lookup also denied HTTP 403. No branch, PR or native CI execution. Automatic PR trigger added locally; actionlint 1.7.12 and whitespace checks pass. Destination main 90ca762 and local PHANTOM merge without conflicts (git merge-tree), but newer upstream code not included in previous frozen-source test claims. Full details: IMPLEMENTATION_CYCLE_04.md.

Cycle 04 delivery update: after user installed the connector, installation 172153173 became visible and git push succeeded. Branch phantom/m0-m2-iphone and draft PR #1 exist. GitHub reports MERGEABLE. Unsigned Mac compile 38937180677 and regression CI 38937180923 started; no outcome is yet claimed. Prior 403 evidence remains historical, not a current access blocker.

## Cycle 05 — cloud regression repair

CI run 38937180923: 1,927 passed, one failed, five skipped, seed 1681970481, on PR merge snapshot including newer main localization tests. Release-script macOS job passed. Test-only lifecycle cleanup leak reproduced locally (25 passed / one failed) and fixed (26 passed). No production consent change. See IMPLEMENTATION_CYCLE_05.md and cycle05-telemetry logs. Full CI rerun and native compile outcome remain required.

Cycle 05 fresh cloud CI 38938290983 passed on b099da8 PR merge snapshot: 1,928 tests passed, five skipped (seed 586175333); 51 quiet tests passed (seed 3382694367); 556 files formatted clean; analyzer no issues; macOS release-script job passed. Summary cycle05-cloud-ci-summary.log. Native run 38938290988 still pending outcome.

Cycle 05 native run 38938290988 passed; unsigned Runner.app artifact 12062890468 is 65,296,937 bytes, SHA256 79d80e1c5b1933d986f949350183e7985751ff8592538a2e89903899f5b78dfd, expires 2026-10-23. Compile-only plist correction verified. Native Swift/plugin compilation passed; no native runtime, signing or physical gate passed. Summary cycle05-native-success-summary.log.

## Cycle 06 — consented screen interpretation

Reused retained remote capture/encoder, added local preview and explicit per-request image consent. Separate one-request ScreenInterpreter has no device tools/RPC/history, bounded immutable PNG and late-response cancellation. Public OpenRouter ChatContentImage data URL contract/model image capability checked without a key. Focused simulated tests: 52 passed; formatter 558 Dart files unchanged; analyzer no issues. Tests cover actual remote entry/return in portrait and landscape, consent defaults/reset, STOP/background, hostile tool proposals, immutable/size/dimension limits, wire payload, model filtering, disconnect capture clearing and GIF recording protection. Cloud/native outcome pending; no private inference or physical test. See IMPLEMENTATION_CYCLE_06.md.

Cycle 06 cloud run 38944294329: 1,940 passed, one navigation-budget failure, five skipped (seed 1969671259). Corrected via central AppRoute.phantomScreen registry and shared top-route guard; did not relax budget. Focused navigation/privacy/remote suite: 57 passed with that seed. Native run 38944294342 passed on pre-navigation-fix 571009f; final native/cloud rerun required. Cancelled 5af3863 runs as superseded.

Cycle 06 FINAL: ebeb4ac PR merge snapshot passed CI 38945364560 (1,941 tests / five skipped, seed 966313376; 51 quiet tests, seed 870753310; 560 formatted files, analyzer clean). Native build 38945364466 passed and uploaded unsigned artifact 12067070178, 65,317,813 bytes; SHA256 8bfe43f3008e3fdabd96316c142711630000f5874c523be928d8c166cca56d5c; expires 2026-10-23. Summaries cycle06-cloud-success-summary.log and cycle06-native-success-summary.log. Live provider, signing, physical BLE and native masking/runtime remain unverified. Final evidence branch phantom/evidence-cycle06 preserves passing source head.

## Cycle 07 — reviewed on-device voice draft

Workspace restarted with unfinished, unuploaded voice work; restored GitHub evidence branch 14da891 and pinned recursive source. SDK rebuilt from pinned 3.47.1 tag; dependency lockfile enforced. Eleven new simulated voice cases plus existing chat/controller suite: 39 passed. Initial 29-pass/eight-failure run corrected unused voice cancellation timers and an invalid test lifecycle transition. Native Speech APIs checked against public Apple docs; plist parsed. No microphone, native permission/runtime, paid inference or hardware operation occurred. Full cloud/native source verification pending. See IMPLEMENTATION_CYCLE_07.md.

Cycle 07 final pre-upload suite: 49 passed (13 voice, 28 existing chat/controller, eight error-policy checks); analyzer clean; format checked 561 Dart files unchanged. Cancellation acknowledgement failure is returned and shown in UI without native details. No signing, audio capture or paid inference performed.

Cycle 07 initial cloud CI 39126865452: 1,953 passed / one unawaited policy failure / five skipped, seed 3816894737. Native build 39126865424 passed. Explicit awaited timeout cancellation and UI catchError added without relaxing budgets; unexpected rejection test added. Focused rerun: 61 passed with the failing cloud seed. Intermediate local replacement/compiler failure retained in cycle07-intermediate-patch.log. Final source CI/native rerun pending. Git CLI token returned HTTP 401; connected GitHub tools remain authenticated as the owner, so delivery can use that existing authorized connection.

Cycle 07 reconciliation: source branch advanced to owner commits 8183c1a/ee13ed6/383782f while local work was checked. Inspected changes and preserved guarded wrappers/history. Added sanitized UI feedback and test on top; no force push or overwrite. Reconciled source verification follows.

Cycle 07 final integrated source a31c07f: CI 39127848306 passed with 1,955 tests / five skipped (seed 1236824613); 51 quiet tests (seed 2846591398); 563 formatted files; clean analyzer; macOS release-script job passed. Local/remote tree equality checked (77598765f6caa707d178e112f57bca8aecd893e3). Native run 39127848307 still pending outcome. Summary cycle07-cloud-success-summary.log.

Cycle 07 final native evidence: run 39127848307 / job 117676637922 succeeded on a31c07f. Xcode built unsigned Runner.app; artifact 12137321309 (65,348,338 bytes), SHA-256 4e50ec88049228ff61458fdb78b0ffdc80c75ce5e2045fcfdf8f2c1da56a7af2, expires 2026-10-25T12:42:56Z. Final cloud/native log summaries retained. This proves compilation only, not microphone/runtime, hardware, signing or installation. Evidence-only branch phantom/evidence-cycle07 retains the verified application source unchanged.

# PHANTOM cycle 05 — cloud test isolation repair

## Verified failure and repair

GitHub regression run 38937180923 on the PR merge snapshot completed with 1,927 passed, one failed and five skipped, seed 1681970481. The failing assertion was telemetry_lifecycle_test: coming up / the switch being off installs nothing. The PR merge snapshot includes newer main localization tests, so its count differs from cycle 03's pinned local snapshot. macOS release-script tests passed; format, analyzer and workflow lint passed. The quiet job did not run after the regression failure.

Reproduced locally with exactly the CI seed: 25 passed / one failed. A direct stop in a preceding lifecycle fixture while its sharing preference remains true schedules asynchronous reconciliation which can reinstall shared sinks during the next test. The factory now registers per-instance cleanup: clear injected failures, set consent off, drain scheduled work, stop and dispose its settings before shared hooks reset. It captures the owned fixture rather than mutable next-test variables. No production diagnostics or consent behavior changed. Focused rerun with the failing seed: 26 passed, zero failed.

Exact files: test/telemetry_lifecycle_test.dart; docs/IMPLEMENTATION_CYCLE_05.md; docs/IPHONE_INSTALLATION.md; docs/evidence-ledger.md; docs/evidence/cycle05-telemetry-repro.log; docs/evidence/cycle05-telemetry-fixed.log. Installation notes corrected to reflect the connected repository and running Mac job. Format and whitespace checks pass. Full cloud rerun required before declaring regression resolved across the merge snapshot.

## Native gate

Unsigned Mac compile run 38937180677 is still compiling; no native success, hardware operation, signing or installation is claimed. Next task: push the cleanup, inspect the new cloud regression and native compile outcomes, fix observed failures and document results.

## First native failure and compile-only correction

Mac run 38937180677 completed with failure after CocoaPods and Xcode compilation: Xcode's resource copy requires ignored ios/Runner/GoogleService-Info.plist, which is absent without real Firebase secrets. The unsigned workflow now generates a valid plist containing only PHANTOM_COMPILE_ONLY=true. It uses exclusive creation so existing configuration is not overwritten, and creates no fake working Firebase account or credentials. This remains a non-installable compile artifact, not a release configuration. actionlint and plist parsing are checked locally; new Mac execution remains required. Additional exact changed files: .github/workflows/phantom-ios.yml and docs/evidence/cycle05-native-failure.log.

## Fresh cloud regression passed

Run 38938290983 on b099da862ae50a1d04a0081096184394524b4fcf PR merge snapshot passed: 1,928 tests passed, five skipped (seed 586175333), plus 51 quiet-build tests passed (seed 3382694367). Formatting checked 556 Dart files unchanged and analyzer reported no issues. macOS release-script job passed. Summary: docs/evidence/cycle05-cloud-ci-summary.log. Native run 38938290988 still compiling; do not infer native success from the regression pass.

## Native compile passed

Run 38938290988 succeeded on b099da862ae50a1d04a0081096184394524b4fcf PR merge snapshot. Xcode built build/ios/iphoneos/Runner.app; artifact 12062890468 (phantom-ios-unsigned-compile) was uploaded, 65,296,937 bytes, SHA256 79d80e1c5b1933d986f949350183e7985751ff8592538a2e89903899f5b78dfd, expiring 2026-10-23. Native Swift/plugin compilation now verified; native Keychain runtime, BLE, signing, installation and Firebase operation remain unverified. The artifact is unsigned and uses marked compile-only configuration, and is not an installable or release build.

Build: https://github.com/jajabinkio-commits/qUnleashed/actions/runs/38938290988
CI: https://github.com/jajabinkio-commits/qUnleashed/actions/runs/38938290983
Artifact: https://github.com/jajabinkio-commits/qUnleashed/actions/runs/38938290988/artifacts/12062890468
Evidence summaries: cycle05-cloud-ci-summary.log and cycle05-native-success-summary.log. Final evidence-only files also include docs/ACCEPTANCE_STATUS.md and docs/RELEASE_READINESS.md. Source was frozen for final CI; final evidence documentation is committed locally without triggering duplicate cloud builds. PR description records the final results remotely.

Next engineering slice: consented, bounded screenshot interpretation using the preserved remote screen pipeline. Signing/distribution requires an authorized PHANTOM bundle/team identity and Apple account workflow; complete M1 physical gates and M2 functionality remain pending. No full milestone/release completion is claimed.

# PHANTOM cycle 05 — cloud test isolation repair

## Verified failure and repair

GitHub regression run 38937180923 on the PR merge snapshot completed with 1,927 passed, one failed and five skipped, seed 1681970481. The failing assertion was telemetry_lifecycle_test: coming up / the switch being off installs nothing. The PR merge snapshot includes newer main localization tests, so its count differs from cycle 03's pinned local snapshot. macOS release-script tests passed; format, analyzer and workflow lint passed. The quiet job did not run after the regression failure.

Reproduced locally with exactly the CI seed: 25 passed / one failed. A direct stop in a preceding lifecycle fixture while its sharing preference remains true schedules asynchronous reconciliation which can reinstall shared sinks during the next test. The factory now registers per-instance cleanup: clear injected failures, set consent off, drain scheduled work, stop and dispose its settings before shared hooks reset. It captures the owned fixture rather than mutable next-test variables. No production diagnostics or consent behavior changed. Focused rerun with the failing seed: 26 passed, zero failed.

Exact files: test/telemetry_lifecycle_test.dart; docs/IMPLEMENTATION_CYCLE_05.md; docs/IPHONE_INSTALLATION.md; docs/evidence-ledger.md; docs/evidence/cycle05-telemetry-repro.log; docs/evidence/cycle05-telemetry-fixed.log. Installation notes corrected to reflect the connected repository and running Mac job. Format and whitespace checks pass. Full cloud rerun required before declaring regression resolved across the merge snapshot.

## Native gate

Unsigned Mac compile run 38937180677 is still compiling; no native success, hardware operation, signing or installation is claimed. Next task: push the cleanup, inspect the new cloud regression and native compile outcomes, fix observed failures and document results.

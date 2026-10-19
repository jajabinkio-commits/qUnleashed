# Cycle 08 — TestFlight preparation

Implemented manual signed archive/export workflow and optional explicit App Store Connect upload, isolated distribution identity, signing profile/configuration preflight, temporary keychain cleanup and iPhone-owner installation guide. Working BLE/RPC, app behavior and dependencies unchanged. No Apple assets configured, Apple network call made, signing attempted or build uploaded. No signed installable app exists.

Validation: bash syntax passed; Python compile passed; three simulated preflight tests passed (matching distribution identity, device profile rejection, compile placeholder rejection). Repository actionlint 1.7.12 passed. Missing-settings negative test exits 1 naming APPLE_TEAM_ID. No macOS signed build ran; export/upload API and actual provisioning remain UNVERIFIED. A Linux preflight simulation is not native signing evidence.

Files: .github/workflows/phantom-testflight.yml; .github/scripts/phantom/testflight.sh; prepare_signing.py; prepare_signing_test.py; docs/IPHONE_INSTALL.md; docs/IMPLEMENTATION_CYCLE_08.md; docs/evidence-ledger.md; docs/FEATURE_MATRIX.md. No capability promoted to physical PASS. Next owner dependency: Apple Developer enrolment, followed by secure app/signing setup. Next engineering gate: real signed archive without upload, then physical validation before distribution.

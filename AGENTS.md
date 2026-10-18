# PHANTOM — mandatory Codex instructions

This repository is a working qUnleashed fork, not a blank project. Read
`docs/MASTER_PLAN.md`, `docs/UPSTREAM_AUDIT.md`,
`docs/EVIDENCE_LEDGER.md`, `docs/FEATURE_MATRIX.md` and
`docs/ACCEPTANCE_TESTS.md` before working.

1. Preserve the existing FlipperClient, session binding, RPC protobuf, BLE
   transport, firmware and working .fap components. Inspect code and confirm
   an actual defect before recommending replacement.
2. Use tested, dependency-injected adapters. Never instantiate a second global
   Flipper client in a PHANTOM feature.
3. Each AI operation must pass typed schema validation, capability check,
   policy and consent, dispatch, observed outcome and structured audit. Do not
   execute raw model text as shell, Flipper CLI, file path or radio payload.
4. Unknown capability is UNVERIFIED, not available. Never claim hardware
   verification from a mock or controller event.
5. Test existing behavior before changing it. Keep existing app builds and
   tests passing. Do not alter original iOS bundle IDs or upstream releases
   without a separate explicit release decision.
6. Respect GPL-3.0 and submodule notices. Never put API keys in source, git,
   logs or analytics; iOS credentials belong in Keychain.
7. On iPhone, BLE support does not imply arbitrary USB serial or DFU access.
   Those features use an optional authenticated computer/USB bridge.
8. Limit remote-radio and identity-related actions to authorised, user-owned
   systems and explicit operations. Require confirmation for transmissions,
   writes, deletions, installs and firmware/DFU operations.
9. Preserve iOS foreground/background limits: do not promise autonomous
   overnight execution or durable background radio access.
10. Evidence reset: facts, assumptions, contradiction, lowest-risk diagnostic
    and minimal next action. Avoid unsupported compatibility guesses.

### After every iteration
Report: changed files, build/test commands actually run, results (PASS, FAIL,
BLOCKED, NOT RUN), physical-hardware evidence, capability changes, security
changes and the next concrete engineering task. Never invent tool output.

### First milestone
Read existing `lib/pages/devices/controllers/device.dart`. Review
`lib/phantom/device/device_gateway.dart` and
`lib/phantom/ai/action_gate.dart`. Run
`flutter test test/phantom_device_gateway_test.dart test/phantom_action_gate_test.dart`
and address real failures without touching working BLE. Then wire a read-only
device status panel into the existing navigation using the injected
DeviceController. Only then enable remote command candidates.


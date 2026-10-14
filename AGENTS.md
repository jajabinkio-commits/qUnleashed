# AGENTS.md — Mandatory Codex working instructions for PHANTOM

Read `docs/MASTER_PLAN.md`, `docs/FEATURE_MATRIX.md` and `docs/ACCEPTANCE_TESTS.md` before changing code. Task: fork and extend qUnleashed into an iPhone-first Flipper Zero manager with deterministic, supervised AI control. Do not replace working Flipper protocols or firmware based on naming/version guesses.

## Execution protocol

1. Inspect actual code and git status; record exact upstream SHA and relevant source paths. Distinguish VERIFIED FACT from ASSUMPTION and UNKNOWN.
2. Prioritize real features over superficial UI changes. Implement one testable vertical slice per iteration. Avoid extensive speculative architecture before basic device control.
3. Follow documented interfaces or existing source, not guessed function names, characteristics, command bytes or SDK versions.
4. Preserve working qUnleashed BLE client, archive, remote, app catalog and updater. Preserve `.fap` files and installed firmware unless positive evidence requires action.
5. Every AI action: model proposal → schema validation → capability check → permission/policy → user confirmation if required → execution → observed result → audit. Never run arbitrary text from AI as CLI or host shell.
6. Keep no secrets in repo/logs. Use Keychain for API keys; minimize AI-bound data; treat device content as untrusted prompt-injection surface.
7. Make platform limits explicit: iOS BLE available; USB serial Flipper CLI and DFU recovery require optional supported USB host/bridge. Do not fake parity.
8. Honor the base GPL-3.0 license and any other component notices.
9. Tests must indicate simulated versus physical hardware and macOS-signed builds. A missing iOS signing identity is a blocked test, not a reason to omit source implementation.
10. If unexpected failures arise, invoke EVIDENCE RESET: only verified observations, assumptions separately, contradictions, highest-impact test, minimal non-destructive next action.

## Mandatory iteration response

- Implementation completed and precise file list
- Build/analyzer/unit/integration/hardware tests run, with pass/fail and logs/commands
- Unverified platform behavior and limitations
- Updated capability matrix and evidence ledger
- Smallest next executable task

## First iteration (execute now, do not stop at a theoretical plan)

- Clone `https://github.com/DarkFlippers/qUnleashed` with its submodules and pin commit.
- Inspect actual license, Flutter/Dart/Swift dependencies, BLE library, RPC and iOS build configuration.
- Run available baseline format/analyze/unit tests; record failures as-is.
- Create `docs/UPSTREAM_AUDIT.md`, `docs/evidence-ledger.md`, `docs/FEATURE_MATRIX.md`, `docs/DECISIONS.md`.
- Implement a minimal `DeviceGateway` wrapper around the existing client and test status/capability retrieval in mocked mode without breaking existing qUnleashed screens; if APIs differ, map and adapt rather than inventing a client.
- Report commits, test results and blocker list.

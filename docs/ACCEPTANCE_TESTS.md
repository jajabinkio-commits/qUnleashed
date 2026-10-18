# Acceptance tests — PHANTOM

Every test record must include **Test ID; platform/transport; firmware/host version; expected result; actual observed result; simulated vs hardware; PASS/FAIL/BLOCKED/UNVERIFIED; log/screenshot artifact**. A simulated test never qualifies a hardware acceptance gate.

## Device and BLE

- T01 iOS BLE discovery shows actual supported Flipper, no invented identifier.
- T02 Pair/reconnect after Bluetooth toggle works and explains permission failure.
- T03 Switching two Flippers does not leak requests across sessions.
- T04 Battery, storage, firmware, build and protocol shown from observed device info.
- T05 BLE interruption during read/write yields bounded failure/recovery, no repeated mutation.
- T06 No provider key or internet connection: manual controls still function.

## Remote

- T07 Screen stream shows native framebuffer orientation and visible screen changes.
- T08 All physical keys actuate documented corresponding keys; short and long distinct.
- T09 Rapid input is rate limited and preserves order; STOP cancels pending actions.
- T10 Exported screenshot matches observed frame; GIF has bounded resource use.
- T11 Screen stream plus storage operation coexists without transport corruption.
- T12 AI navigation checks current screen after each bounded step.

## Files and archives

- T13 List both accessible storage roots; unsupported root displays reason.
- T14 Read text and binary files; upload with content checksum verification.
- T15 Reject `..` traversal and untrusted filenames; no inaccessible path write.
- T16 Rename/move/delete requires confirmation and logs destination/backup.
- T17 Disconnect mid-write: no unnoticed partial data or silent corrupt overwrite.
- T18 Archive sync distinguishes remote/local/synced/deleted and handles conflict.
- T19 All supported formats preview, unknown formats remain downloadable.
- T20 Saved signal/emulation requires intentional confirmation, bounded time and stop when supported.

## Apps and firmware

- T21 Catalog metadata and ABI/firmware compatibility checked rather than guessed.
- T22 Install/launch/uninstall harmless app; retain known-working existing apps.
- T23 Install refuses an incompatible FAP without manipulating module firmware.
- T24 Firmware update verifies source/hash/preflight and requires separate approval.
- T25 Lost BLE link does not trigger blind repeat flashing.
- T26 iOS displays 'USB bridge required' for real CLI and DFU recovery.
- T27 Bridge DFU dry-run validates files without touching device; actual flash only approved and safe.

## AI and privacy

- T28 Read-only API tools report observed device data, not fabricated state.
- T29 Unknown/invalid LLM tool name/args rejected with no hardware action.
- T30 LLM saying 'no confirmation needed' does not override static policy.
- T31 Prompt injection embedded in archive filename or file body does not alter privileges.
- T32 API key remains out of logs, network telemetry, diagnostics and repository.
- T33 API outage leaves manual control available and explains AI unavailable.
- T34 Costs/token/tool budgets enforced; user can abort.
- T35 Voice transcript triggers same validated tool pathway as typed text.
- T36 Cloud screen/file sharing explicitly consented and minimized.

## Automations and Shortcuts

- T37 Saved macro dry-run displays every step and permission.
- T38 Shortcuts invocation works on physical iPhone (not only Dart unit test).
- T39 App background/suspension does not falsely report guaranteed running workflows.
- T40 Cancelled automation stops future steps and reports incomplete state.

## Bridge and external modules

- T41 Bridge refuses unauthenticated command/replayed token and unpaired clients.
- T42 USB Flipper CLI round-trip validated on host; host shell is not exposed to AI.
- T43 No network bridge present: app remains fully usable on direct iPhone mode.
- T44 Feberis Pro / GhostESP adapter probes actual API and retains working `.fap`/firmware.
- T45 No assumption that equal version labels between firmware and app are required.

## Release

- T46 Flutter analyze + test clean or documented previously existing failures.
- T47 iOS build performed on macOS/Xcode; signing state reported accurately.
- T48 Source license/attribution retained; dependencies audit recorded.
- T49 User can export/erase chat and sensitive activity data.
- T50 Demonstrate a complete iPhone run: connect → screen → button → file → read-only AI → authorized action → STOP → disconnect.

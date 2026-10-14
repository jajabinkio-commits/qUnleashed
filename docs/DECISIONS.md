# PHANTOM decisions

## D001 — Preserve the pinned stack

FACT: qUnleashed already implements the requested manual subsystems and has a passing simulated baseline. Decision: keep its client, session queue, screens and submodule commits unchanged. New code uses constructor injection and the existing route registry. Official sources are pinned reference checks, not replacement transport code.

## D002 — First vertical slice is local read-only inspection

Implement `DeviceGateway`, immutable observations and capability evidence; adapter calls actual client extensions for status and safe directory listing. A Device-tab route exposes status inspection without any AI/provider prerequisite. Keep absent values absent; show individual read failures. No mutation, emulation, flashing, CLI or arbitrary action entry point is added. The later validated action executor is not represented as implemented by this interface.

## D003 — Capability evidence is operation-specific

FACT: seeing an RPC protocol version does not demonstrate every operation. Only successful status response bodies establish those exact capabilities. NOT_IMPLEMENTED establishes unsupported; unavailable/invalid/timeout leaves unverified. Remote/buttons/apps/updater implementations remain preserved but unverified. iPhone CLI/DFU always say bridge required; module telemetry requires an evidenced adapter. Invalidate readings on every connection event, including same-device reconnect.

## D004 — Bind every request, reject stale observations

FACT: foreground RPCs bypass task binding. All inspection requests use an existing session binding and unattended priority. Check cancellation generation, device token, live binding and RPC readiness before/after awaits. STOP/backgrounding cancels follow-on requests and discards late responses. It does not physically retract the one RPC already sent; that request drains or times out. Shared manual client is never disconnected by closing the adapter.

## D005 — Separate build evidence from hardware gates

Mock tests replace wire response frames while retaining real API extension decoding. Flutter unit/widget/bundle results do not pass iOS pairing or signing gates. Do not advance M1 as complete or advertise an installable iPhone application until actual M1 hardware acceptance and macOS/Xcode checks pass.

## D006 — Privacy and retry behavior require a focused next slice

FACT: upstream default diagnostics/replay and startup Firebase differ from PHANTOM's privacy contract; upstream uploads may restart on reconnect. Those findings are explicit release/M2/M3 blockers, not silent omissions. Preserve the audited baseline in this cycle. Next implementation changes defaults and consent behavior with regression evidence before provider secrets are introduced. No dependency versions or cloud account settings are guessed.

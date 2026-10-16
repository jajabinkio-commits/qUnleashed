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

## D007 — iPhone-only scope and privacy consent

User confirmed iPhone-only operation and asked engineering to handle implementation. Retain direct BLE/manual functions; USB CLI/DFU remain explicitly bridge-required. Signing and hardware tests cannot be fabricated. Apple membership is not yet established. New PHANTOM preference keys intentionally ignore legacy diagnostics/replay/push choices, default false and fail closed on unreadable/malformed preferences. Replay requires separate opt-in. The notification backend initializes only after an explicit category opt-in; revocation disables auto-init, unsubscribes topics and deletes the token. Native migration/revocation still needs device validation.

## D008 — Implement source despite unavailable hardware, preserve gates

The user's instruction and AGENTS require real implementation even when iOS signing/hardware is absent. Implement a first M2 read-only source slice with simulated tests while keeping M1 and full M2 hardware gates unpassed. Do not represent the first slice as the complete AI subsystem. No write or radio tool is exposed.

## D009 — Verified OpenRouter wire contract and least data

Read OpenRouter's public OpenAPI and public model catalog on 2026-10-15. Function names permit letters/digits/underscores/dashes, not dots, so map local `device.status`/`device.capabilities` to wire `device_status`/`device_capabilities`. Offer only these two custom functions. Validate the entire batch, empty arguments, device continuity, consent and budgets before reading; no general model-selected executor exists. One-send status consent resets after Send. Exclude identities, filenames, files, screens and arbitrary raw info fields; don't retain status results/derived answers as later provider context. Normal text history is memory-only and erasable.

## D010 — Native credentials and bounded provider behavior

Use iOS Security.framework Keychain in the existing implicit-engine registration path, with a fixed account/service, non-synchronizing and WhenUnlockedThisDeviceOnly accessibility. No preferences/plaintext credential fallback. Native code is not yet compiled on macOS. Requests use fixed HTTPS OpenRouter endpoints and bearer headers; no AppHttp telemetry hook, raw provider error body or key-bearing exception is logged. Reject a known key pasted into prompts and redact an echoed key. Bounds: 3 completions, 4 tools, 512 output tokens/completion, 25-second HTTP completion timeout, 45-second workflow deadline, request/response byte limits. These do not constitute a hard dollar cap; provider credit/cost verification remains pending.

## D011 — Cloud compilation is distinct from installation

Prepare a manual macOS-15 GitHub Actions compile check using pinned Flutter and recursive submodules. It builds an unsigned debug app with the test Firebase placeholder, does not publish and requires no Apple signing key. Lint locally; mark remote execution unverified until observed. Signed installation still requires an authorized Apple/app identity/distribution workflow and user account sign-in.

## D012 — Separate generated explanations from observations

Controller-owned immutable evidence accompanies a chat turn. Only completed gateway status/capability reads populate it; model text is never parsed into a reading card. Observed battery/storage/protocol and missing-value markers are presented separately from AI narrative, which is labelled as an explanation. A no-observation message appears if no tool returned data, and already completed reads survive provider-reply failure. Numeric battery values outside 0–100/nonfinite data remain unknown. Timestamped cards are historical chat evidence, not a live dashboard. Evidence is memory-only, bounded with the conversation, cleared for each request/STOP and erased with local chat; it is never added to provider history.

## D013 — Use the supplied fork after authorization is verified

The supplied destination `jajabinkio-commits/qUnleashed` exists publicly with default branch main. The connected account `jssanderson93-svg` has pull=true, push=false, admin=false; collaborator-permission lookup returned HTTP 403 due to integration access restrictions. Remote upload and macOS Actions execution remain blocked until the owner connects GitHub with repository write access. Recheck permissions before writing. The separate pocketpal-ai project was not modified. No publishing or signing credential was used.

## D014 — Explicit one-screenshot interpretation without device tools

Reuse RemoteSession.capturePng and the retained screenshot encoder. Snapshot recent frames (10-second entry limit), clear raw frame provenance on disconnect/device switch, pause remote visuals while preview is open and resume on return. Preview is local only; each cloud Send requires a fresh switch choice. Filter image capability from public model architecture.input_modalities, without requiring tools for vision-only requests. ScreenInterpreter sends one bounded PNG (8 KiB, fixed encoder dimensions), two messages, no tools/history/device executor and at most 512 output tokens. The existing HTTP size/time limits apply; STOP/background invalidates late responses. Interpretation stays labelled as AI inference and remains erasable in memory. Images/results are not saved to disk or copied to clipboard. Mark AI pages SensitiveSurface for existing replay masking; native masking remains unverified.

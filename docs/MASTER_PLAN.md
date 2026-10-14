# PHANTOM — Complete Codex Engineering Specification

**Version:** 1.0 | **Prepared:** 14 October 2026 | **Target:** iPhone + Flipper Zero + optional companion bridge

## 0. Executive mandate

Build an installable iPhone application called **PHANTOM** that combines a full-featured qFlipper-style management interface and a controlled AI agent. It must support direct Bluetooth Low Energy (BLE) communication with the Flipper Zero from an iPhone, multi-turn natural language and voice commands, live device screen mirroring and remote buttons, files/archives, app management, firmware updates, device diagnostics and user-configurable automations. The optional companion bridge must expose capabilities that iOS cannot provide directly (USB serial CLI and full USB DFU repair). Include an extensibility layer for supported external Flipper apps and GPIO modules without presuming all have an RPC interface.

**Primary strategy:** Fork the existing **DarkFlippers/qUnleashed** Flutter app and work with its existing embedded `flipperlib` code, rather than rebuilding a Flipper BLE protocol stack. Preserve proven functions unless tests prove defects. Treat the official Flipper iOS app and official protobuf definitions as cross-checks, not arbitrary replacements. Don't use any unverified API, dependency, firmware feature, capability or path as though established.

**Completion contract:** a feature is DONE only when it has implementation, a defined target platform, automated coverage, hardware test instructions and an observed result. A feature blocked by Apple or device hardware is **BRIDGE REQUIRED**, not DONE on iOS and not silently omitted. A feature depending on modified firmware is **OPTIONAL EXTENSION**, not claimed for stock firmware. Firmware updates and device recovery are different capabilities.

**Deliverables:** fork/repository, Flutter iOS app, reusable typed device-operation API, AI chat/voice/actions, automation system, optional bridge daemon with authenticated transport and desktop tooling, tests, release pipeline, licensing notes, supported-function matrix, operator guide and documented limitations. Package a signed iOS test build through an Apple-supported distribution route when signing credentials are provided. Never claim a signed IPA or physical hardware testing without actually doing it.

---

## 1. Verified sources and constraints

1. Base project: https://github.com/DarkFlippers/qUnleashed — Flutter, iOS BLE, multi-device, device info, firmware update, remote desktop, archive, file manager, app catalog, GPS/network extension and toolbox. **GPL-3.0**: preserve copyright, attribution, source obligations and compatible licensing for the derivative. Inspect full LICENSE, third-party notices and git submodules before altering.
2. qUnleashed's embedded client: `lib/modules/flipperlib` per its `pubspec.yaml`. Public Dart API: https://pub.dev/packages/flipperlib . **Inspect the vendored version first**, not the package's latest API by assumption.
3. Official iOS implementation: https://github.com/flipperdevices/Flipper-iOS-App (MIT licensed according to repository). Use to verify native iOS Bluetooth behavior and interoperability; copying between projects requires maintaining licence notices and checking each dependency's license.
4. Official RPC definitions: https://github.com/flipperdevices/flipperzero-protobuf ; use pinned source revision, generate wrappers and track firmware/protocol compatibility. `gui.proto` documents screen streaming and button keys/events.
5. Official firmware/update docs: https://docs.flipper.net/zero/basics/firmware-update ; iOS BLE firmware updating is supported, and microSD is needed for usual updating. qFlipper offers computer-connected repair.
6. Apple Core Bluetooth: https://developer.apple.com/documentation/corebluetooth ; background access is constrained by app state and OS. No guarantee of perpetual background BLE or agents. iOS cannot use qUnleashed's USB serial/DFU path. For device testing/distribution, use a Mac with Xcode or a properly configured macOS CI environment and Apple signing.
7. AI API: https://openrouter.ai/docs/guides/features/tool-calling and https://openrouter.ai/docs/guides/features/structured-outputs . Model proposals must be validated on-device against a typed tool registry. JSON schema is an aid, **not** a safety boundary.

Record exact source revision, source URL, license, API interface and hardware/firmware versions in `docs/evidence-ledger.md`. Recheck upstream before adopting changed libraries.

### Non-negotiable truths

- **iOS direct:** BLE-based RPC, GUI streaming, button control, files, saved item interactions when supported, apps, device info and normal firmware update.
- **iOS direct does not include:** general USB serial CLI; full USB DFU recovery. These require an optional bridge on a supported USB host or separately verified new iOS API capability. Display the limitation explicitly.
- **Advanced peripherals:** Feberis Pro / GhostESP / ESP32 / GPIO functions depend on firmware and the specific Flipper app/module protocol; support by measured adapter, not guessed BLE commands. Never overwrite a working `.fap` or firmware merely because version numbers differ.
- **Security:** AI must not call arbitrary shell commands, send uncontrolled radio output, overwrite arbitrary files, flash firmware, execute BadUSB payloads or carry out irreversible actions without explicit typed permissions and human confirmation. No clandestine, unauthorized or credential-gathering workflows.

---

## 2. Product boundaries and personas

**User environment:** iPhone first; Flipper Zero; may use customized Flipper firmware and external GPIO hardware; must not require Android; optional desktop/Raspberry Pi/other supported USB host allowed for full-recovery tasks. Prefer operation with **no always-on backend** for iPhone direct mode. Cloud LLM requires internet; manual control must remain functional without it.

Three user interaction modes:

- **Manual:** qFlipper-style menus and controls, no AI dependency.
- **Copilot:** AI explains device state, suggests commands and returns proposed actions for review.
- **Agent:** AI executes explicitly allowed low-risk typed actions, observing their results after each step. Any outbound signal, risky command, delete, file overwrite, app/script run or firmware change requires confirmation as set by policy.

Preserve an emergency **STOP** button, disconnect/abort control, cancellation on app backgrounding when necessary, audit history and per-workflow limits (tool count, deadline, bytes, radio actions and cost).

---

## 3. Capability model and complete feature requirements

Every action is surfaced through `DeviceCapabilities`, dependent on device/firmware/protocol, transport and entitlement. Use one of `supported`, `unsupported`, `unverified`, `bridgeRequired`, `requiresExtension` and present the reason in UI. On iOS, never display a terminal/DFU item as available when only USB works.

### 3.1 Device connection and management

- Scan for BLE peripherals; verified discovery filter/service identifiers from existing stack; pair/bond and connect, reconnect, disconnect and forget device.
- Persist multiple paired Flippers and alias names; display signal/connection, firmware and RPC/protocol version, battery/charging, device identity, build date, storage, mount state and available extensions.
- State machine: idle, scanning, pairing, connecting, authenticating, ready, reconnecting, disconnected, updating, failure. Show user-actionable errors and prevent racing sessions.
- Request IDs, timeouts, flow control, proper chunk sizes and backpressure using existing flipperlib. No invented packet formats.
- BLE background restoration only within OS limits. No guarantee that a suspended iPhone keeps an AI automation running.

### 3.2 Remote desktop and device interaction

- Stream Flipper screen live at the device's native 128x64 monochrome resolution, resize without altering binary pixel data, support orientation. Observe reconnects, frames dropped and responsiveness.
- Virtual Up, Down, Left, Right, OK, Back including short, long and repeat/hold where supported; match documented `gui.proto` input event pairing.
- Tap/gesture mapping to navigation with long-hold, visual state, keyboard accessibility, haptic feedback; no hidden key activation.
- Save PNG screenshot, record GIF of frame changes with frame-count/storage limits, open share sheet.
- AI `get_screen`, `press_button` and `navigate_screen` (max 10 steps per plan, check visual result after each step). Optional vision model or local pixel analysis may interpret screen, with confidence and failure escalation; screen text recognition is not ground truth.
- Support virtual display if authenticated/available from actual protocol; not a substitute for physical screen stream.

### 3.3 Storage and archives

- Browse `/ext` (SD) and `/int` (internal, where permitted) with path metadata; directory listings; safe normalization and sandboxed path whitelist.
- Create/move/rename/delete files and folders; import/export via iOS Files; edit known text formats and binary download/upload; checksums, chunked transfer resume on validated offset, error/progress states.
- Local-first per-device archive: favorites, categories, tags, smart search, thumbnail/previews, remote-only/local-only/synced/deleted state, restore, import and backup export. Avoid overwriting existing names silently; use diff and conflict resolution.
- Format-aware views for IR `.ir`, Sub-GHz `.sub`, NFC `.nfc`, RFID `.rfid`, iButton `.ibtn`, BadUSB `.txt`, JavaScript `.js`, FAP `.fap`, wardriving captures and unknown files. Treat unknown or firmware-specific extensions as files, not proof of launchability.
- Saved item launch/emulation via documented RPC or app launch only when supported; require confirmation and explicit duration for transmitted/emulated content, with cancellation.
- Full device/user-data backup and restore **where RPC access permits**; excluded protected areas clearly identified. Verified manifest and hash check, dry run, recovery copy, report.

### 3.4 Apps and extensibility

- Load official Flipper app catalog; query/search/filter categories; app details/screenshots, compatibility, installed vs preinstalled, install/update/uninstall, progress and error reporting.
- Validate firmware/ABI/app compatibility **from metadata**; do not infer it from matching version strings. Preserve known-working `.fap` until positive incompatibility evidence.
- Launch/stop supported installed apps through RPC, pass documented arguments only. Not all apps expose RPC: provide manual screen navigation fallback with explicit UI indicators.
- Plug-in manifest format: identifier, required firmware/extensions, supported operations, connection path, permission/sensitivity, test vector, capability probe, version and maintainer.
- Optional adapters: Feberis Pro/GhostESP/ESP32 Marauder/GPS modules and other GPIO devices **only** after discovering their actual interfaces; no universal magic 'module API'. Start read-only status/telemetry before adding commands. Preserve existing working GhostESP app/firmware.
- Built-in qUnleashed toolbox features to retain if in selected fork: Pixel Draw/animation, IR remote library, pulse plotter, saved-location map, MIFARE diagnostics; do not remove during refactoring. Any cryptographic recovery feature is for user-authorized tags and must not auto-execute.

### 3.5 Firmware lifecycle and device repair

- Read build/version/firmware channel; fetch signed or authenticated release manifest from trusted source where available; inspect checksum and release metadata; preflight battery and microSD, user backup, confirm source/channel.
- Support stock firmware BLE update and qUnleashed-supported alternate firmware channels as separate explicit choices, with compatibility check and rollback/retry guidance. No silent custom-firmware switch.
- A lost BLE link during update must have safe reconnect/recovery messaging rather than repeated blind flash attempts.
- **Full DFU recovery:** route to bridge service using desktop USB/libusb with out-of-band user approval. Provide recovery preparation checklist and verify connected USB identity, selected image/hash and device power. If no bridge: display 'Requires computer/USB'; supply exportable repair instructions.
- Never use a 'matching version number' heuristic to replace working companion applications or external module firmware.

### 3.6 AI agent, APIs and natural language

- OpenRouter via user-provided API key; optional other OpenAI-compatible endpoints behind provider interface, selected by explicit user setting. Model selection, cost preview, token limits, latency, vision support, tool support and graceful provider failure. **Local Ollama only via a reachable LAN/bridge service**; do not claim iPhone runs desktop Ollama unassisted.
- Secure credential storage via iOS Keychain/Flutter security wrapper; no API key in logs, git, screenshots, crash telemetry, URL query strings or AI prompts. Default: send minimally necessary device telemetry and only after an AI request.
- Chat UI with conversation history, device status, attached device screen/files only with consent, tool-call timeline and readable interpretation of outcomes. Separate **Observed / Inferred / Unknown** in AI status responses.
- Native speech-to-text/dictation permission and typed input; optional spoken answer via local iOS text-to-speech. Voice input never activates hardware without normal authorization path.
- Model may emit ONLY `ActionProposal` objects via structured tools. Deterministic validator enforces JSON schema, tool allowlist, device capabilities, user scope, path restrictions, bounded arguments, explicit confirmation and request-specific nonce. Reject hallucinated tools, out-of-range parameters, unavailable capabilities, unpaired devices and expired state.
- Tool execution loop: **inspect → propose → validate → confirm (if required) → execute → observe result → report**; call-site enforces budget and stop regardless of model instruction. Reject prompt injection from file content, app names, terminal output and archive filenames.
- AI must never infer that an operation happened from its own text. It reports actual RPC acknowledgment and/or separately confirmed device state. Correlation IDs and logs for every execution.
- Optional `planner` for 2–5-step workflows; avoid unchecked bulk command plans. Refresh device state before each step. Explicit STOP cancels queue and turns off active emulations when an API provides a stop operation.

### 3.7 Automations and Apple Shortcuts

- User-defined named routines/macros composed only of typed safe operations, no arbitrary Dart/JS/Python interpreted from LLM output.
- Triggers: manual, app open, supported Shortcuts/App Intents, user-invoked Siri/voice action, and iOS-permitted scheduling. Do not advertise autonomous overnight/offline radio actions while iOS is suspended.
- Shortcut intents: connect known device, read status, open remote, take screenshot, list saved keys, request AI action plan, run saved permitted routine. Support parameters/result reporting, iOS permission model and confirmation requirements.
- Macro replay dry-run mode, execution transcript, versioned steps, undo/restore for file modifications where feasible, interruption handling.

### 3.8 Companion bridge for full parity

Bridge is optional, separately installed and authenticated; cannot depend on Android. It can run on macOS/Linux/Windows or a suitable SBC, subject to upstream supported USB serial/DFU stacks. Host is connected to Flipper via USB, and iPhone talks to bridge via authenticated TLS transport on LAN (remote use only through secure VPN or explicitly scoped encrypted tunnel).

- Pair bridge with iPhone using one-time QR/token plus device-bound long-term keys; prohibit open, unauthenticated network API.
- Expose **typed** methods: bridge identity/capabilities, transport health, CLI read/execute (user-initiated, explicit high-risk approval), USB RPC proxy if applicable, firmware DFU repair with user approval, controlled logs and rescue status.
- Do NOT expose an unrestricted general operating-system shell through the AI interface; raw console is a separate advanced manual mode with explicit opt-in. Distinguish Flipper CLI from host shell.
- AuthN/AuthZ by role and specific device; deadlines, concurrency limits, replay protection, local TLS certificate pinning/credential rotation, auditable actions. Physical USB reconnection handled cleanly.
- Bridge protocol schema and tests stored in repository; typed JSON over HTTPS/WebSocket acceptable, but not raw protobuf exposed unguarded to the internet.

### 3.9 Settings, diagnostics and UX

- Home dashboard: selected device, battery, firmware, storage, BLE status, actions; tabs: **Device | Remote | Files | Archive | Apps | AI | Automations | Toolbox | Settings**. Responsive dark UI; large virtual controls.
- Diagnostics: transport/state logs, RPC request latency, stale firmware detection from metadata, battery, storage, external module detection when verified, export sanitized debugging bundle.
- Local-only mode; configurable cloud data sharing; erase chat/history; optional Face ID app lock if requested; privacy notices for GPS/location, microphone, Bluetooth.
- No advertisements, analytics or unsolicited telemetry by default; network endpoints visible to user.
- Feature flags/experimental opt-in for firmware-specific methods; never obscure unsupported items.

---

## 4. Concrete architecture

```text
+---------------------------------------------------------------------+
| iOS Flutter app (PHANTOM)                                            |
| Dashboard | Remote | Files/Archive | Apps/Firmware | AI | Shortcuts |
+---------------+-----------------------+-----------------------------+
                |                       |
      DeviceCommandBus           AgentCoordinator
                |             (tools + policy + audit)
                |                       |
        CapabilityRegistry          AIProvider
                |             OpenRouter / optional LAN
      FlipperRpcAdapter                 |
                |                 Structured proposals
   BLE via existing flipperlib          |
                |              Validation + confirmation
           Flipper Zero <--------------+
                ^
                |
       optional authenticated USB host bridge
       (typed CLI + USB RPC + DFU repair)
```

### Package responsibilities

- `lib/phantom/core/`: typed `Action`, `Result`, `Error`, `DeviceSnapshot`, `Capability`, policy primitives, audit metadata.
- `lib/phantom/device/`: reuse existing `FlipperClient`; thin wrapper `FlipperGateway`, transport observer, capability probes, pairing/session handling, request queue. Never duplicate lower-level protobuf except genuine missing features.
- `lib/phantom/features/remote/`, `/files/`, `/archive/`, `/apps/`, `/firmware/`, `/devices/`: presentational screens and feature services, ideally adapt existing qUnleashed features rather than duplicating.
- `lib/phantom/ai/`: `AIProvider`, `OpenRouterProvider`, model selection, redaction, tool registry, executor, plan state machine, chat UI, audit, token/cost limits, voice module.
- `lib/phantom/automations/`: typed routine DSL, validation, scheduling and Shortcuts/App Intents bridge.
- `lib/phantom/bridge/`: paired bridge client with typed wire schemas.
- `lib/phantom/extensions/`: optional third-party device/app integration manifest and adapters.
- `packages/phantom_bridge/` or `bridge/`: host daemon implemented in a language chosen after inspecting upstream dependencies (Python or Rust are candidates), with integration tests and sample config. No fake simulated command execution in production.
- `test/`, `integration_test/`, `docs/` as described below.

**These are proposed new paths.** Codex must inspect actual upstream Flutter architecture and adapt placement rather than overwrite preexisting types or guess package layouts.

### Typed operation interface (design contract)

```dart
abstract interface class DeviceGateway {
  Stream<DeviceSnapshot> watchDevice();
  Future<CapabilityReport> discoverCapabilities();
  Future<OperationResult> execute(ValidatedDeviceAction action);
  Future<void> cancel(String operationId);
}

abstract interface class AgentPolicy {
  PolicyDecision evaluate(
    ActionProposal proposal,
    CapabilityReport capabilities,
    PermissionGrant permissions,
  );
}
```

Do not treat these as upstream APIs: they are PHANTOM abstractions Codex should implement while wrapping actual qUnleashed functions.

### AI action envelope (MUST be schema-validated)

```json
{
  "proposal_id": "uuid",
  "device_id": "paired-device-id",
  "operation": "screen.capture",
  "arguments": {},
  "reason": "Inspect current screen",
  "requested_capability": "gui.screen_stream",
  "requires_confirmation": false
}
```

The last field is advisory from the model, **not** authoritative; the app's static policy determines confirmation. Device IDs, operation names and schema must be validated against actual registry. The model cannot supply authorization or fabricate `ValidatedDeviceAction`.

### Initial allowed tool catalogue

Use exact, explicit names and strongly typed arguments:

| Tool | Required arguments | Risk treatment |
|---|---|---|
| `device.status` | device ID | Read-only |
| `device.capabilities` | device ID | Read-only |
| `screen.capture` | device ID | Read-only; consent before cloud upload |
| `screen.press` | key, press type, bounded duration | Rate limit, bounded plan |
| `files.list` | sanitized path | Read-only |
| `files.read` | sanitized path, size limit | Sensitive content consent for model |
| `files.write` | allowed path, contents/checksum | Preview diff + confirm |
| `files.rename` / `files.delete` | sanitized paths | Confirm; backup where possible |
| `archive.search` | category/query | Read-only |
| `archive.run_saved` | known item ID, duration | Confirm, stop support, controlled RF output |
| `apps.list` | pagination/filter | Read-only |
| `apps.launch` | known compatible app ID | Confirm if script/RF-capable |
| `apps.install` / `apps.remove` | verified package metadata | Confirm + rollback guidance |
| `firmware.check` | channel | Read-only |
| `firmware.update` | signed manifest ID | Separate high-impact confirmation |
| `bridge.cli` | validated command context | Bridge only; explicit elevated permission |
| `bridge.dfu_repair` | verified image manifest | Bridge only; mandatory multi-step confirmation |
| `automation.run` | approved saved routine ID | Validate steps individually |

Operations with materially different capabilities must have separate tool IDs and permissions. `archive.run_saved` must not conflate sending an RF signal, NFC emulation, and running a BadUSB script; implement individual typed subclasses and risk gates.

### Protocol rules

- Obtain protobuf definitions and firmware RPC matrix from pinned official source and selected project's vendored code. No reverse-invented frame identifiers.
- Respect transport framing, version handshake, request/response sequence, flow control, asynchronous stream events, retries with idempotency rules and reconnection.
- Serial use (bridge) and BLE use (iPhone) can have different available features. Export an explicit transport-bound capability list and update on firmware change.
- Avoid simultaneous conflicting updates/transfers; use a serialized device mutation queue while allowing safe reads/streams as supported.
- Partial writes: atomic staging temp path + checksum + rename, if Flipper filesystem permits; otherwise use backup/read-back verify and record limitations.
- Treat all device responses and file content as untrusted input.

---

## 5. Security, safety and reliability invariants

1. No LLM message directly invokes RPC. Every execution passes schema validator, authorization, capability check, policy decision and audit record.
2. All mutations have human-readable target and effect. Confirm irreversible actions, file deletions, app installs, RF transmission/emulation, BadUSB/script launches, firmware operations, and advanced bridge CLI.
3. No hidden actions, remote control by a third party, persistence that circumvents iOS restrictions, radio jamming, credential harvesting, unlock bypass or malicious HID automation.
4. Keychain stores provider keys and bridge private credentials; API keys never enter device files/logs. Redaction tests must prove that secrets cannot leak in logs, crash reports or exported diagnostics.
5. Support cancel, pause, disconnect and max-runs. Use exact allowlists for paths and per-tool scopes, e.g., reject `..`, symbolic/alias escapes where relevant, `/int` modification unless explicitly allowed.
6. Firmware update: verify trusted origin, manifest, signature/checksum if available, firmware compatibility, preconditions, battery; never silently replace custom firmware or working `.fap`.
7. Agent state persisted minimally; redact data before sending to cloud. File names, read results and screen captures can contain prompt injection: treat as content, not instructions.
8. Conservative retries: a timeout on an irreversible operation must trigger **query actual device state first**, not blindly replay the operation.
9. Host bridge LAN-only by default, bound to loopback until paired, mutual authentication or pinned-device token, TLS, request replay prevention, revocation and rate limiting.
10. Never represent mocked success as hardware success. Tests labelled simulated/integration/hardware separately.

---

## 6. Execution phases for Codex, with hard gates

### Phase 0 — Reconnaissance and evidence baseline

1. Clone qUnleashed recursively and record exact git SHA; read its README, LICENSE, `pubspec.yaml`, `CLAUDE.md`, submodules, iOS target/config, CI and existing tests.
2. Map real screen, file, app, firmware, BLE and RPC code locations and named Dart interfaces. Consult official iOS and proto sources for compatibility. Generate `docs/UPSTREAM_AUDIT.md`, `docs/evidence-ledger.md` and `docs/FEATURE_MATRIX.md` with direct source references.
3. Record test host OS, Flutter/Dart versions, Xcode availability, Apple signing availability and hardware availability. Run `flutter pub get`, `flutter analyze`, `flutter test`; document actual results. Do not claim iOS release if build environment unavailable.
4. Confirm license requirements and whether qUnleashed submodules can be redistributed. Check privacy/third-party analytics dependencies. Mark existing working functions as preserved.
5. Determine exact firmware device support by capability inspection rather than software-version name matching.

**Gate:** Baseline reproducible (or clearly documented blocker), upstream test status recorded, source audit and capability design approved in files.

### Phase 1 — Device abstraction + preserved manual functionality

1. Implement `DeviceGateway` adapter around actual existing RPC client; add strongly typed commands and capability discovery without replacing existing device stack.
2. Wrap connection state and errors; verify BLE scan/pair/read status. Build/retain dashboard and multi-device switching.
3. Preserve remote screen with button actions, screenshot and GIF; file manager, archive, app catalogue and firmware update UX.
4. Add operation queue, timeouts, structured results and cancellation; ensure manual functions work when no AI account/key is configured.
5. Write simulated tests and manual device acceptance checklist.

**Gate:** In a physical hardware test: pair iPhone, view screen, press button, list `/ext`, transfer sample text file and launch a harmless app. No regression against baseline.

### Phase 2 — AI provider and read-only copilot

1. Add provider interface for OpenRouter and optionally other user-configured API endpoints; endpoint/model compatibility discovery, response parsing, timeout/retry, usage and cost cap.
2. Keychain storage and provider settings; chat + dictated speech + optional TTS; privacy controls and cloud consent.
3. Start only with tools `device.status`, `device.capabilities`, `screen.capture`, `files.list`, `archive.search`, `apps.list`, `firmware.check`.
4. Validate tool-call payloads against schemas; implement agent loop with bounded calls and error explanations. Add inference-vs-observation labeling.
5. Attack-test prompt injection from screenshot captions, filenames, file text, app names and tools. Mock malformed/hostile model outputs.

**Gate:** AI can correctly answer 'What's on the screen?' and 'How much space is available?' using observed data, and cannot call a write tool.

### Phase 3 — Validated actions and automation

1. Enable `screen.press` with explicit, bounded steps and visual recheck after each action.
2. Add file upload/edit/move/delete, app install/launch/remove, saved-item actions, firmware update via per-tool policy and preflight confirmations.
3. Implement execution ledger and undo/restore where feasible, request ids, progress, cancellation, action expiration and device-state verification.
4. Add preconfigured routines and user-built macros with individual permissions and preview/dry run.
5. Add iOS Shortcuts/App Intents bridging and test on real iPhone. Integrate voice request -> AI typed plan -> confirmation -> RPC -> observed result.

**Gate:** End-to-end supervised multi-step command works on Flipper and every destructive/signal-emitting action is blocked until user confirms; STOP works.

### Phase 4 — Extended native/iOS features

1. Integrate iOS Files import/export, screenshots, GIF sharing, Notifications if applicable, accessibility controls, privacy controls, BLE reconnection and state restoration.
2. Preserve toolbox modules from upstream (IR library, pixel draw, pulse plotter, saved locations, MIFARE tools if present). Resolve compile and UI regressions.
3. Show current transport and firmware-specific capability tags; offline manual mode; device backup/restore and per-device archive.
4. Test on at least two firmware configurations when available; never change test firmware as a first-line remedy for API uncertainty.

**Gate:** Complete iPhone-direct feature matrix; no fake USB terminal/DFU option.

### Phase 5 — Optional desktop/USB bridge

1. Select host platform and programming language based on verified upstream USB/DFU implementation; build a small typed service, not a full parallel app.
2. Separate **Flipper CLI** from **host OS shell**; support manual terminal and optional narrowly scoped AI CLI tools with high-impact confirmation.
3. Bridge USB RPC, list device/capabilities, provide repair flow with signed image validation and physical confirmation.
4. Pair via QR/one-time local token and authenticated TLS, with revocation, audit, device-binding and replay prevention.
5. Add iPhone bridge selection, status, typed operations, disconnect flow and reasonable failure recovery.

**Gate:** USB terminal demonstrates real command round-trip; recovery dry-run validated without flashing, then tested only on safe hardware under explicit approval. No unauthenticated endpoints.

### Phase 6 — External module adapters (incremental)

1. Audit Feberis Pro/GhostESP and any other named module: exact firmware, existing working `.fap`, communication interface, documented commands, telemetry. Do **not** rewrite or reflash working elements from assumptions.
2. Add capability probes and read-only status, then device-specific adapter using existing RPC app if supported, otherwise screen-navigation fallback or bridge-specific documented integration.
3. Add a human-approved capability manifest and an automated mock for each module; flag unsupported methods transparently.

**Gate:** Tests prove selected module works without changing working versions or substituting a guessed RPC API.

### Phase 7 — Hardening and delivery

1. Audit logging/Keychain/secrets/HTTPS/TLS; fuzz RPC parser interfaces and tool parameter schemas; test interleaved screen stream plus file transfers.
2. Run `dart format`, `flutter analyze`, `flutter test`, iOS build validation on a macOS host, bridge unit/integration tests, protocol conformance tests and vulnerability/dependency review.
3. Automate iOS simulator build where suitable; real BLE requires physical iPhone/Flipper. Prepare signing/provisioning and TestFlight/approved distribution as available.
4. Produce README, installation guide, advanced bridge guide, permissions guide, privacy notes, troubleshooting tree, supported firmware matrix, known issues, changelog, license/source attribution.
5. Run the complete acceptance checklist; mark **PASS**, **FAIL**, **BLOCKED**, or **UNVERIFIED** with evidence. Release only when P0/P1 completed or explicitly scoped.

**Gate:** Reproducible signed or buildable release, hardware test report and no high-severity security issues.

---

## 7. Non-negotiable acceptance scenarios

See `ACCEPTANCE_TESTS.md` for detailed cases. Minimum release criteria:

A. **iPhone-only manual**: first install; BLE pair/reconnect; screen mirrors; arrows/OK/Back; remote screenshots; file list/read/upload; app install; device status; supported firmware update; no AI needed.
B. **AI from phone**: voice/text request → typed read-only query → result; multi-step screen interaction with per-step visual check; write/emit actions gated by policy; clear failure on unsupported function; audit trail.
C. **Asset integrity**: upload then verify hash; restore original on conflict; archive sync handles mid-transfer disconnect without unnoticed corruption.
D. **Compatibility**: official and custom firmware cases where available; preserve working apps, no forced version-number alignment; external module recognition is evidence-based.
E. **Full parity with bridge**: authenticated USB Flipper CLI; USB DFU recovery workflow and visible user approval; no silent ability to run host shell.
F. **Security**: arbitrary invented tool not executed, malicious filename doesn't change agent policy, no key in logs, device unplug/timeout doesn't trigger blind retry, STOP stops pending actions.
G. **Release**: clean builds on supported platforms; actual signed iOS build needs Apple signing; physical device results explicitly documented.

---

## 8. Development conventions

- Preserve original repository git history, upstream remotes, license files and attribution. Keep modifications under separate feature branches; document dependency versions and lockfiles.
- New code must be typed, testable and modular; no giant single-file UI, no hard-coded Flipper device UUID from guesswork, no unexplained synchronous delays, no random sleeps to handle protocol races.
- Add feature-level tests before enabling AI write-capable tools; require mocked and integration paths, negative security tests and runtime capability checks.
- Use existing Flutter architecture/state manager where suitable; do not force a rewrite solely for a preferred framework.
- Maintain `docs/DECISIONS.md`: facts, assumptions, options, selected decision, rationale, verification. Document when a shortcut is blocked and fallback plan.
- Every Codex iteration: inspect → implement smallest coherent vertical slice → run tests → record results → commit → next slice. Do not ask the user to repeatedly reselect choices settled by this plan.
- When environment lacks Bluetooth/iPhone signing, produce the real code and test it with mocks and platform builds as far as possible, then list exact remaining physical steps. Never fabricate tool outputs.
- On regressions, **EVIDENCE RESET**: facts, separate assumptions, contradictions, test highest-impact premise, preserve working components and take minimum defensible action.

---

## 9. Project milestones and release criteria

| Milestone | Deliverable | Release gate |
|---|---|---|
| M0 | Audited fork and repeatable build/test baseline | CLI tests run; legal/stack audit done |
| M1 | iPhone device management stable | Hardware pair, remote, files, apps |
| M2 | AI read-only assistant | Tool validation and screen/status queries |
| M3 | Supervised AI action executor | Explicit confirmations, STOP, logs |
| M4 | Automation, Shortcuts, enhanced archives | Actual Shortcut/device flow verified |
| M5 | Secure USB bridge | CLI and repair capability separately tested |
| M6 | External module integration | At least one evidenced adapter |
| M7 | Installable distribution | iOS signing/build and regression signoff |

Build M0 through M3 before spending engineering effort polishing icons, optional protocol adapters or advanced agent autonomy. That sequence creates an early working product while preserving eventual full scope.

---

## 10. Definition of done and Codex output contract

Codex must maintain the following files:

- `AGENTS.md` — behavioral rules for every coding iteration.
- `docs/MASTER_PLAN.md` — this specification.
- `docs/FEATURE_MATRIX.md` — each feature, source API, platform, state, test and status.
- `docs/evidence-ledger.md` — official URLs, exact revisions and verified observations.
- `docs/DECISIONS.md` — architecture decisions, tradeoffs and alternatives.
- `docs/HARDWARE_TEST_LOG.md` — tested devices, firmware, dates, expected vs observed.
- `docs/RELEASE_READINESS.md` — signing, privacy, GPL, distribution and remaining blockers.

Per implementation turn, report **what changed; exact files touched; tests executed with results; things not tested; blockers; next smallest change**. No indefinite planning loops. Do not report 'working on iPhone' without device test. Avoid mixing firmware module version with companion `.fap` version.

---

## 11. Reference links

- qUnleashed: https://github.com/DarkFlippers/qUnleashed
- qUnleashed README: https://github.com/DarkFlippers/qUnleashed/blob/main/README.md
- qUnleashed package config: https://github.com/DarkFlippers/qUnleashed/blob/main/pubspec.yaml
- flipperlib docs: https://pub.dev/documentation/flipperlib/latest/
- Official iOS app: https://github.com/flipperdevices/Flipper-iOS-App
- Official protobuf: https://github.com/flipperdevices/flipperzero-protobuf
- GUI protobuf: https://github.com/flipperdevices/flipperzero-protobuf/blob/dev/gui.proto
- Firmware update: https://docs.flipper.net/zero/basics/firmware-update
- Apps: https://docs.flipper.net/zero/apps
- iOS Core Bluetooth: https://developer.apple.com/documentation/corebluetooth
- OpenRouter tool calling: https://openrouter.ai/docs/guides/features/tool-calling
- OpenRouter structured output: https://openrouter.ai/docs/guides/features/structured-outputs
- Apple iOS app signing: https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html

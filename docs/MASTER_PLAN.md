# PHANTOM — Codex implementation contract (iPhone-first)

## Objective
Extend the connected qUnleashed fork to deliver qFlipper-quality device
management plus supervised, explainable AI actions and Apple Shortcuts on
iPhone. An optional authenticated USB host bridge provides capabilities
unavailable to an iOS BLE client. Existing working app behavior must survive
every milestone. The exhaustive user-supplied spec was also distributed as
`PHANTOM_Codex_Complete_Plan.zip` (14 Oct 2026); this in-repository document
is the actionable design summary.

## Required end-state feature groups
1. **Device:** discovery/pairing, multiple devices, connect/reconnect, firmware
   version and build, battery, SD/internal storage, raw diagnostic values.
2. **Remote:** live screen stream, six virtual buttons with press/release,
   hold, screenshots and GIF capture; stop session cleanly and rebind to the
   original Flipper rather than an accidentally switched device.
3. **Files:** /int and /ext browser, transfer, preview, text edit, create,
   rename/delete with confirmation, backup and restore; reject traversal and
   recheck device identity before applying writes.
4. **Archive/signals:** synchronize and organize saved infrared, Sub-GHz, NFC,
   RFID, iButton, Bad USB and JS files; launch only protocol-supported actions
   on devices and systems the operator is authorized to control. No automatic
   destructive operations or unsafe unsolicited transmissions.
5. **Apps:** catalogue, device compatibility, install/update/delete, launch
   where supported, download validation, support alternative firmware's
   capabilities without replacing a working .fap based on version names.
6. **Firmware:** stock/custom channel selection, backup, integrity checks,
   battery/SD preflight, update monitoring, recovery instructions and
   full USB DFU recovery only over verified host bridge.
7. **AI:** OpenRouter and extensible providers; typed function/tool calls,
   model chooser, chat, natural language, mic dictation, speech output,
   opt-in screen understanding and file attachments, per-call cost visibility,
   strict data minimization and API keys stored in iOS Keychain.
8. **Automation:** user-built finite macros, dry-run, action history,
   confirmation checkpoints, cancel/STOP, App Intents/Shortcuts and
   background policies that comply with iOS lifecycle restrictions.
9. **Toolbox:** preserve existing IR library, pixel drawing, pulse plotter,
   saved locations, read-only diagnostics and existing NFC tools; add gated,
   tested extension adapters for Feberis Pro, GhostESP and ESP32 modules only
   after reading their actual documented interfaces.
10. **Optional bridge:** device-bound authentication over TLS on LAN, typed
    Flipper CLI commands, USB RPC and confirmed DFU recovery on supported
    macOS/Linux/Windows hosts. No unauthenticated API, general OS shell or
    open-internet RPC.
11. **Product:** settings, accessibility, dark interface, actionable errors,
    offline/local-only operation, sanitized log export, privacy controls,
    iOS code signing and Apple-supported distribution, GPL compliance.

## Trust and execution model
AI model output is **proposal** only. Pipeline:
input -> candidate structured tool -> exact schema -> capability probe ->
scope/permission -> explicit consent for high-risk actions -> serial command
dispatch -> independently observed result -> audit record. Failure at any
stage rejects execution. Text from archives, captured media, app names and
terminal output is untrusted data, never tool authority.

## Source architecture
Existing `FlipperOneClient` and `DeviceController` are the sole physical
session owners. `lib/phantom/device/device_gateway.dart` injects the existing
controller. `lib/phantom/ai/action_gate.dart` begins with only two allowlisted
read-only actions. The bridge, voice and UI are separately isolated features.
Avoid migrating the entire qUnleashed state-management framework.

## Iterations and gates
- M0: pin source and submodule SHA; inspect existing APIs, licensing, iOS
  constraints, baseline tests and actual CI.
- M1a: read-only typed snapshot + watch + capability discovery + guard, with
  mocks. **Implemented on development branch; tests require Flutter runner.**
- M1b: wire read-only PHANTOM status view to existing DeviceScope; verify on
  real paired iPhone/Flipper.
- M2: remote screen/button wrappers + capture, non-disruptive UI; test stop,
  disconnect and active-device switches.
- M3: storage, archive and app actions with typed parameter validation and
  confirmation; integrate existing features rather than rewriting them.
- M4: OpenRouter adapter, Keychain, structured tool calls and explanation UI;
  disable any AI mutation until independent policy and tests pass.
- M5: mic/TTS/vision, macros, Shortcuts/App Intents, dry-run, cancellation.
- M6: firmware/update and optional authenticated USB CLI/DFU bridge.
- M7: external-module adapters, hardware matrix, regression testing, signed
  TestFlight distribution with authorised signing credentials.

## Completion criteria
No feature marked DONE without implementation path, automated test, hardware
verification where required and observed output. Mark missing tests as BLOCKED
or NOT RUN. Maintain `docs/FEATURE_MATRIX.md` and `docs/EVIDENCE_LEDGER.md`
after each change. Bundle a build only after code signing; do not call Dart
source a signed IPA.


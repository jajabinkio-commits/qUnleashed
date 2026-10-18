# PHANTOM implementation cycle 02 — 2026-10-15

**Outcome:** opt-in privacy and consent migration, plus an executable first read-only AI chat slice for the iPhone app. Source remains pinned to qUnleashed upstream `975e3ebd810091a31212abb2998ffb7628363069`, following local cycle 01 commit `70751b55bfe433e949b2ff7e1ebd45b8e1290b02`. All recursive submodule pins and hosted dependencies/lockfile are unchanged. Full M1/M2 physical acceptance and M3–M7 are not complete.

User scope: iPhone-only usage; engineering to do the implementation. Apple Developer membership is not established. No Mac, iPhone/Flipper hardware, signing identity, remote build destination or private AI credential is attached. No account sign-in, paid inference, remote push, Apple upload, firmware replacement or RF operation occurred.

## Implementation

### Privacy

- Error reporting and screen replay start off, and require separate explicit choices. PHANTOM-specific versioned preference keys ignore legacy qUnleashed values, including legacy notice acknowledgments; dismissing the new notice never enables sharing.
- Preference read/type failures leave sharing off. Reporting lifecycle captures the **loaded** replay choice before starting the SDK, so a change during native startup is not lost.
- Push categories start off. Firebase initialization/notification permission requests wait until the user enables a category. A serialized settings path rechecks consent after asynchronous initialization; dev-channel choice alone cannot start notifications.
- Revoking the last category disables token auto-init, unsubscribes topics and deletes the token; later disabled starts avoid token churn. Native iOS/Android auto-init defaults are false in platform configuration. Native permission/token migration/replay behavior still needs device verification.
- Notification controls remain retryable after setup errors and display a general configuration/connectivity explanation rather than falsely declaring every error a signing failure.
- Existing active-reporting tests now explicitly opt in. They continue testing real active/teardown behavior instead of relying on the old default.

### First read-only AI slice

- Add PHANTOM AI from the Device tab without replacing manual screens or transport. It works as a source-level UI even with no Flipper connected; no AI request is made on startup. Actual provider use requires the user's key/service and internet.
- Load available tool-capable models using OpenRouter's public catalog, then select a model. Public catalog/schema were fetched and checked without credentials or paid inference.
- Implement fixed-endpoint HTTPS bearer chat with bounded request/response parsing and sanitized errors. Unknown/malformed model tool calls cannot reach a general RPC, shell, write or radio executor.
- Offer exactly two custom wire tools: `device_status` and `device_capabilities`, mapped to local `device.status` and `device.capabilities`. The underscore mapping follows OpenRouter's documented function-name restriction.
- Validate the entire batch before a read: exact allowlist, empty argument object, function type, bounded/unique call IDs, current device, consent and tool budget. A safe read followed by an invalid operation in the same batch is rejected before any read RPC.
- Device status sharing is off by default and is consumed/reset by **each Send**. Filter status to bounded firmware/power/protocol/external storage fields and issues; omit identifiers, filenames, arbitrary device fields, files and screenshots.
- Device results and derived answers are not retained as later provider context. Normal text-only chat history is memory-only, bounded and erasable. Erase affects the local app; provider-side retention follows provider policies.
- STOP/backgrounding closes the provider, cancels future gateway reads and discards late results. An in-flight RPC/request may already have been sent and cannot be undone or refunded. Old request timeouts cannot cancel a later request started after STOP.
- Bounds: 3 completions, 4 tool calls, 512 requested output tokens/completion, 6 ordinary history messages, 2,000-character input, 20,000-byte input envelope, 65,536-byte completion response, 25-second completion timeout and 45-second workflow deadline. Reported aggregate token usage is checked before continuing. **No hard dollar cost cap is claimed.**

### iPhone credentials and cloud build preparation

- Native Security.framework Keychain channel in the existing implicit-engine registration path, with a fixed per-app service/account, non-synchronizing storage and `WhenUnlockedThisDeviceOnly` accessibility. No SharedPreferences/plaintext credential fallback. Save/read/update/delete use actual `SecItem` APIs, with errors that contain no key values.
- Key entry is obscured and cleared after saving. The current key is placed only in the Authorization header, never in prompts, tool data or diagnostic errors. Reject messages containing the active key; redact it if echoed by a provider.
- Dart channel behavior and HTTP boundaries are simulated/tested. **Swift/Keychain have not been compiled or exercised on macOS/iPhone.**
- Add a manual `macos-15` workflow with recursive checkout, pinned Flutter, test Firebase placeholder, analysis, unsigned native iOS compile and compile-artifact upload. Workflow lint passes. No workflow has run remotely. Its unsigned `.app` is not installable or a signed IPA/TestFlight build.

## Verification

Final results: see the observed table below and `docs/evidence/`. Final source verification was run after implementation was frozen; source hashes are recorded. Simulated tests do not satisfy physical acceptance.

| Check | Actual result | Evidence |
| --- | --- | --- |
| Focused privacy/reporting/notice/settings | 87 passed, simulated | `evidence/cycle02-privacy-test.log` |
| AI/provider/security | 19 passed, simulated | `evidence/cycle02-ai-final.log` |
| AI + chat UI | 23 passed, simulated | `evidence/cycle02-ai-ui-final.log` |
| Combined shutdown/privacy/AI/UI | 43 passed, simulated | `evidence/cycle02-final-focused.log` |
| Format | PASS: 551 Dart files, no changes, exit 0 | `evidence/cycle02-format-final.log` |
| Analyzer | PASS: no issues, exit 0 | `evidence/cycle02-analyze-final.log` |
| Frozen-source full regression, seed 20261015 | PASS: 1,906 passed / 5 skipped, exit 0 | `evidence/cycle02-regression-final.log` |
| Quiet logging configuration | PASS: 51 tests, exit 0 | `evidence/cycle02-quiet-test.log` |
| Linux-target Dart kernel/assets build | PASS: Dart kernel/assets compiled, exit 0; no native iOS validation | `evidence/cycle02-bundle-final.log` |
| Workflow lint | PASS: pinned actionlint 1.7.12, exit 0 | `evidence/cycle02-workflow-lint.log` |
| Public OpenRouter catalog | PASS: 462 models, 393 advertising tools at observation time | `evidence/cycle02-openrouter-schema.log` |
| Native Keychain/APNs/BLE/iOS compile/signing | BLOCKED / not performed | `HARDWARE_TEST_LOG.md`, `RELEASE_READINESS.md` |
| Private AI round-trip, voice, vision, write execution | NOT VERIFIED / not performed | `FEATURE_MATRIX.md` |

Intermediate failures are retained. Privacy tests initially relied on old always-on defaults and exposed a replay-start snapshot mismatch; fixtures and lifecycle handling were corrected. A UI test initially skipped required lifecycle transitions; the test now follows inactive → hidden → paused and back. The first whole-suite run failed two shutdown tests and two new credential tests while source/tests were still changing. The shutdown fixtures now explicitly opt in; the completed provider guard/redaction passes focused verification. The frozen-source final run above supersedes that inconsistent intermediate run. Existing five prerequisite-dependent skips never count as hardware passes.

## Remaining scope and next executable work

- Physical M1 pairing/reconnect, remote/buttons, file integrity, catalog/app and firmware regression remain unverified. Preserve existing working firmware/apps.
- Full M2 still needs live provider/native Keychain testing, cost enforcement, screen capture/vision, files/archive/apps read tools, voice/TTS and richer evidence/audit UI. Model narrative remains interpretation; no device action is performed based on it.
- M3 write tools, permissions/confirmations, persisted audit, supervised automation, global operation stop semantics and disconnect/read-back safeguards are not implemented. This slice exposes no such operations.
- Shortcuts/App Intents, advanced iOS release features, modules, bridge and signed release remain pending. Direct iPhone CLI/DFU are still impossible with the retained stack.
- Public model metadata advertises tool support but does not guarantee every selected provider/model's live behavior. No private credential or credit was available to verify inference. Hard dollar caps and usage/account integration remain pending.
- New English strings use fallback for incomplete translations; no translated ARB was manually edited. Native privacy wording in existing translations still needs review before a multilingual release.
- Current app bundle/release identity is inherited and must be configured as PHANTOM under an authorized Apple account before distribution. Do not enable inherited upstream publishing workflows with upstream service identities.

Next engineering task: run the prepared native iOS compile under a configured cloud/macOS repository, resolve native/plugin compile findings, then implement explicitly consented screen capture/read-only vision and additional bounded read tools. Native signing and a physical iPhone/Flipper run are required before installation/hardware claims. Do not request secrets in chat or claim these gates passed from mock tests.

## Exact added/modified files

- `.github/workflows/phantom-ios.yml`
- `PHANTOM_README.md`
- `android/app/src/main/AndroidManifest.xml`
- `docs/ACCEPTANCE_STATUS.md`
- `docs/DECISIONS.md`
- `docs/FEATURE_MATRIX.csv`
- `docs/FEATURE_MATRIX.md`
- `docs/HARDWARE_TEST_LOG.md`
- `docs/IMPLEMENTATION_CYCLE_02.md`
- `docs/IPHONE_INSTALLATION.md`
- `docs/RELEASE_READINESS.md`
- `docs/evidence-ledger.md`
- `docs/evidence/cycle02-ai-analyze.log`
- `docs/evidence/cycle02-ai-final.log`
- `docs/evidence/cycle02-ai-test.log`
- `docs/evidence/cycle02-ai-ui-final.log`
- `docs/evidence/cycle02-analyze-final.log`
- `docs/evidence/cycle02-analyze.log`
- `docs/evidence/cycle02-bundle-final.log`
- `docs/evidence/cycle02-bundle.log`
- `docs/evidence/cycle02-chat-ui-final.log`
- `docs/evidence/cycle02-chat-ui-test.log`
- `docs/evidence/cycle02-final-focused.log`
- `docs/evidence/cycle02-format-final.log`
- `docs/evidence/cycle02-format.log`
- `docs/evidence/cycle02-l10n.log`
- `docs/evidence/cycle02-openrouter-schema.log`
- `docs/evidence/cycle02-privacy-initial.log`
- `docs/evidence/cycle02-privacy-test.log`
- `docs/evidence/cycle02-quiet-test.log`
- `docs/evidence/cycle02-regression-final.log`
- `docs/evidence/cycle02-regression-test.log`
- `docs/evidence/cycle02-source-hashes.log`
- `docs/evidence/cycle02-style-fixes.log`
- `docs/evidence/cycle02-workflow-lint.log`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`
- `lib/app/routes.dart`
- `lib/components/navigation.dart`
- `lib/main.dart`
- `lib/pages/devices/page.dart`
- `lib/pages/option/diagnostics_notice.dart`
- `lib/pages/option/pages/push.dart`
- `lib/phantom/ai/credentials.dart`
- `lib/phantom/ai/openrouter.dart`
- `lib/phantom/ai/read_only_agent.dart`
- `lib/phantom/features/ai/chat_page.dart`
- `lib/services/notifications/push_service.dart`
- `lib/services/telemetry/settings.dart`
- `lib/services/telemetry/telemetry.dart`
- `test/app_shutdown_test.dart`
- `test/diagnostics_notice_test.dart`
- `test/diagnostics_screen_test.dart`
- `test/phantom_ai_fakes.dart`
- `test/phantom_ai_test.dart`
- `test/phantom_chat_page_test.dart`
- `test/phantom_privacy_test.dart`
- `test/telemetry_lifecycle_test.dart`
- `test/telemetry_test.dart`
- `translations/app_en.arb`

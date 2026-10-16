# PHANTOM cycle 06 — consented screenshot interpretation

Base source b099da8 (prior native/CI pass), local evidence commit 988f166. BLE transport/protocol, submodule pins and dependencies unchanged. Read all contract files; reuse RemoteSession capture and PNG encoder rather than a new RPC implementation.

## Implemented

- Explain screen entry on narrow/wide remote controls; freeze a recent frame, pause streaming during local preview and resume on return. AI entry is disabled during GIF recording/encoding so it cannot interrupt retained recording. Clear capture/timestamp on disconnect or device switch; no fabricated screen when no recent frame exists.
- Preview timestamp and image; per-request sharing switch defaults off and resets on Send/STOP/background. No upload on entry or public model discovery. Key is configured through existing PHANTOM AI; no new credential storage.
- Public model capability filtering for image input, including vision models without tools. Verified official OpenAPI ChatContentImage data-URL contract.
- Dedicated ScreenInterpreter: one image request, no tools/RPC/executor/history, strict immutable PNG byte/dimension limits, existing HTTP limits, 45-second workflow bound, STOP/late-response suppression, plain labelled inference and erase. No paid/private provider call performed.
- AI chat and screenshot pages now use existing SensitiveSurface replay mask marker. Native replay behavior remains unverified.

## Verification

Focused simulation results, analyzer and formatter logs are recorded alongside this report. Full cloud regression and native compile results remain pending upload. No physical BLE, private inference, image recognition accuracy, signing or install gate is passed by mocks. Latest prior native successful build is cycle 05 until new CI finishes.

Limits: screenshot interpretation only; no camera/photo import, live AI screen stream, screen automation, voice, hard dollar cap or image history. Unsupported/oversized captures fail locally; only retained encoder output at 512x256 or 256x512 is accepted. STOP cannot undo an uploaded image/provider billing. Provider retention follows its policies. Manual controls remain the retained implementation.

Next task: freeze this source, push the review branch, verify cloud tests and Mac compile, repair failures and record the actual run results. Then expand native runtime/security coverage and the remaining M2 features.

Observed pre-upload checks: 52 focused simulated tests passed (cycle06-focused.log); analyzer no issues (cycle06-analyze.log); formatter checked 558 files unchanged (cycle06-format.log). Initial analyzer had three style findings, corrected before final verification. The initial added GIF-protection test used a tooltip finder as an IconButton; corrected the finder, then all 52 focused tests passed. Public schema evidence: cycle06-provider-schema.log.

## Exact changed files

- `PHANTOM_README.md`
- `docs/DECISIONS.md`
- `docs/FEATURE_MATRIX.csv`
- `docs/FEATURE_MATRIX.md`
- `docs/IMPLEMENTATION_CYCLE_06.md`
- `docs/RELEASE_READINESS.md`
- `docs/evidence-ledger.md`
- `docs/evidence/cycle06-analyze.log`
- `docs/evidence/cycle06-focused.log`
- `docs/evidence/cycle06-format.log`
- `docs/evidence/cycle06-l10n.log`
- `docs/evidence/cycle06-provider-schema.log`
- `lib/pages/tools/remote/desktop/page.dart`
- `lib/pages/tools/remote/desktop/session.dart`
- `lib/pages/tools/remote/desktop/widgets/wide_body.dart`
- `lib/phantom/ai/openrouter.dart`
- `lib/phantom/ai/screen_interpreter.dart`
- `lib/phantom/features/ai/chat_page.dart`
- `lib/phantom/features/ai/screen_page.dart`
- `test/phantom_screen_page_test.dart`
- `test/phantom_screen_test.dart`
- `test/remote_page_wrist_input_test.dart`
- `test/remote_session_test.dart`
- `translations/app_en.arb`

A final review found the recording/preview interaction after the first upload; the GIF guard and its regression test are a justified source change. Earlier cycle 06 runs are superseded; final cloud checks must target the guard commit. Exact touched files unchanged.

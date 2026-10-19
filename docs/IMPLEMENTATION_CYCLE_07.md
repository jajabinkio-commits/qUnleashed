# PHANTOM cycle 07 — reviewed on-device dictation

**FINAL: source a31c07f passed cloud regression and unsigned iPhone compilation. Physical speech, signing and installation remain unverified.**

Base 14da891 (cycle 06 evidence over tested source ebeb4ac). The workspace restarted before prior unfinished voice work was uploaded. Restored the public repository recursively and rebuilt that work from saved implementation details. Reinstalled pinned Flutter 3.47.1 / Dart 3.13.1 from verified tag 6655482ec0; root release-manifest URLs returned 404, resolved by the SDK's own bootstrap. Dependencies installed with --enforce-lockfile; no protocol, firmware, dependency or submodule revisions changed.

## Implemented

- Speech/AVAudioEngine native channel in AppDelegate, using existing Flutter implicit-engine registration. Permission prompts only after explicit Listen; on-device recognition required, no remote fallback/audio file. Twenty-second capture and eight-second finalization timers; native background/interruption cancellation, generation checks and audio/tap/task cleanup.
- Dart VoiceInput seam with channel/permission timeout, redacted failures and obsolete-transcript rejection. UI injects it for tests; never calls a device executor or AI provider.
- Dictate/Finish/STOP in existing chat; preserves an existing draft, bounds combined transcript length, allows review/edit, and requires the same explicit typed Send. Device sharing resets off. Erase conversation now clears the draft. Permission-dialog inactive alone does not cancel voice, real background does. No voice-channel cancellation when dictation was never active.
- Required iOS usage descriptions. Existing sensitive-page replay marker continues to cover transcript UI. No signing credential or entitlement added.

## Verification and limitations

Final pre-upload focused run: 49 passed (13 new voice cases, 28 existing chat/controller cases and eight repository error-handling checks). Cases cover no startup recording, explicit methods, malformed/oversized transcripts, permission-error privacy, stuck-channel timeout, late results, reviewed Send, permission-dialog lifecycle, STOP/erase, preserved drafts and newer-session isolation. Native API reference and plist parsing recorded in cycle07-apple-api.log/cycle07-plist.log. Formatter/analyzer and final cloud/native results recorded as observed below.

Initial focused run: 29 passed / eight failed. Seven typed-chat failures exposed needless unawaited cancellation timers on dispose when voice had never been used; corrected by only cancelling active dictation. One new test resumed directly from paused, violating Flutter lifecycle; corrected to hidden/inactive/resumed. A 39-case rerun passed, then cancellation acknowledgement and repository checks expanded the final focused run to 49 passing cases. Initial log retained, not hidden.

No physical iPhone/microphone, speech recognition accuracy, native permission/runtime, Keychain runtime, live private AI request, signing or installation was tested here. On-device speech availability/language assets vary; failure retains typing without server fallback. TTS is pending. Full M1/M2 and later milestones remain incomplete. Next task: upload this frozen source, verify the full cloud regression and Mac compile, fix observed failures, then expand native runtime validation and speech playback.

Final analyzer: no issues; formatter checked 561 Dart files unchanged. Added cancellation acknowledgement tests for both channel and user-visible failure. Native microphone/recognition behavior is still unverified; cloud compile must exercise the new Swift source. Evidence logs cover the restored worker, not the lost process; no test result from before the restart is invented.

## Exact changed files before upload

- `PHANTOM_README.md`
- `docs/DECISIONS.md`
- `docs/FEATURE_MATRIX.csv`
- `docs/FEATURE_MATRIX.md`
- `docs/IMPLEMENTATION_CYCLE_07.md`
- `docs/RELEASE_READINESS.md`
- `docs/evidence-ledger.md`
- `docs/evidence/cycle07-analyze.log`
- `docs/evidence/cycle07-apple-api.log`
- `docs/evidence/cycle07-focused-final.log`
- `docs/evidence/cycle07-focused-initial.log`
- `docs/evidence/cycle07-format.log`
- `docs/evidence/cycle07-l10n.log`
- `docs/evidence/cycle07-plist.log`
- `docs/evidence/cycle07-pubget.log`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`
- `lib/phantom/ai/voice_input.dart`
- `lib/phantom/features/ai/chat_page.dart`
- `test/phantom_voice_page_test.dart`
- `test/phantom_voice_test.dart`
- `translations/app_en.arb`

## Initial cloud result and explicit future handling

CI 39126865452 on 393978e: 1,953 passed, one unawaited-future policy failure, five skipped; seed 3816894737. Native Mac build 39126865424 passed, verifying the new Speech/AVAudioEngine Swift source compiles. The cancelled-future results were handled by the callees, but the project requires explicit error handling at each asynchronous boundary. Timeout now awaits the bounded cancellation before raising the already user-visible timeout; UI cancellation chains attach a catchError that reports a generic failure without native data. No policy budget relaxed. Timeout permits at most the 90-second permission/channel wait plus the three-second cancellation wait; native capture remains 20 seconds plus eight-second finalization.

The first patch did not match a formatter-expanded expression and briefly left an unresolved unawaited reference after import removal; caught locally, fixed before upload, intermediate log retained. Final focused rerun with seed 3816894737: 61 passed, including unexpected cancellation rejection handling and the repository future/error-policy checks. New full-cloud/native results required for the corrected source. Native recognition accuracy/permissions remain unverified regardless of compile success.

## Concurrent repository changes preserved

Before updating the branch, a fresh read found new owner-authored commits 8183c1a, ee13ed6 and 383782f, which wrap cancellation in the existing guarded helper. The old-head update was not applied. Retained those commits and their timeout wrapper rather than replacing them; added inner sanitized cancellation-failure feedback and the rejection test on top. The final timeout wrapper retains a 90-second client timeout and separately bounded cancellation (superseding the local awaited-timeout variant above). All subsequent tests target the reconciled tree. GitHub API-created unpublished commit a6390ab is not the review-branch head and is not claimed delivered/tested.

Reconciled pre-upload source: 61 focused tests passed with seed 3816894737; analyzer no issues; 561 Dart files formatted unchanged. Test log cycle07-reconciled-focused.log. The new native Speech implementation remains identical to the source that passed compile run 39126865424; final integrated code still receives its own cloud/native checks.

## Final cloud regression passed

CI run 39127848306 on a31c07f5188a8f5d5dd2ca9648812980c8ca7aa8 PR merge snapshot passed: 1,955 tests passed, five skipped (seed 1236824613), plus 51 quiet-build tests passed (seed 2846591398). Formatting checked 563 Dart files; analyzer no issues; macOS release-script job passed. Reconciled source tree 77598765f6caa707d178e112f57bca8aecd893e3 matched the local tested tree byte-for-byte before branch update. Native run 39127848307 is still running at this observation; its outcome is recorded separately.

## Final native result and delivery

Native run [39127848307](https://github.com/jajabinkio-commits/qUnleashed/actions/runs/39127848307) completed successfully on a31c07f. Xcode compiled Runner.app in 276 seconds. Artifact 12137321309, `phantom-ios-unsigned-compile`, is 65,348,338 bytes, expires 2026-10-25T12:42:56Z; SHA-256 `4e50ec88049228ff61458fdb78b0ffdc80c75ce5e2045fcfdf8f2c1da56a7af2`. This compile-only artifact has no signing and uses test-only Firebase placeholders/upstream identity: it is not an installable release.

Final totals: 1,955 regression tests passed, five skipped; 51 quiet-logging tests passed; 61 focused tests passed locally. Fourteen new voice tests cover the final implementation. Earlier failures above were fixed; no final check failed. Native microphone capture, permissions, recognition accuracy, background cleanup and actual device behavior require physical testing and are not proven by compilation.

The reviewed code remains on `phantom/m0-m2-iphone`, draft PR #1. Final evidence is published separately on `phantom/evidence-cycle07` so the verified source is unchanged. Next executable engineering task: add optional read-aloud replies with stop/background handling and tests. Physical M1/manual controls, native voice checks, signing/distribution and complete M2–M7 remain outstanding.

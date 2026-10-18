import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../logging.dart';
import '../prefs_reader.dart';
import '../settings/persist.dart';
import '../settings/store.dart';

/// Optional diagnostics. PHANTOM requires a fresh, explicit opt-in for both
/// error reports and screen replay. Legacy qUnleashed choices are not consent.
class DiagnosticsSettings extends PrefsBackedSettings {
  static const String _shareLogsKey = 'phantom.diagnostics.share_logs.v1';
  static const String _replayKey = 'phantom.diagnostics.share_replay.v1';
  static const String _noticeShownKey = 'phantom.diagnostics.notice_shown.v1';
  static const bool _defaultShareLogs = false;
  static const bool _defaultShareReplay = false;
  static const bool _defaultNoticeShown = false;

  /// Whether replay can record on this platform at all.
  ///
  /// `ReplayIntegration` gates on `supportsReplay` - `@internal`, with no
  /// public accessor anywhere in `sentry_flutter` **9.30.1**, so this mirrors
  /// it by hand and §7's bump to 10 is the moment to re-check it. It is true
  /// only in the Java binding and, for Cocoa, only on iOS - so the four desktop targets
  /// and web record nothing whatever the rates say. The same shape as
  /// `HomeWidgetService.supported` and `PushService.isSupported`, and here
  /// rather than in `Telemetry` because the Diagnostics screen needs it too
  /// and already holds this object.
  ///
  /// Two things read it: the screen, to leave the row out instead of offering
  /// a switch that does nothing, and `Telemetry._reconcile`, to not tear the
  /// SDK down for a rate nothing will read.
  /// [defaultTargetPlatform] and not `Platform.isAndroid`, which is what the
  /// rest of the app reaches for: a widget test runs on the host, so `dart:io`
  /// would answer Windows and hide the row from the tests that cover it. This
  /// one is overridable through `debugDefaultTargetPlatformOverride`, which is
  /// how `diagnostics_screen_test.dart` pins a phone. It is also the right
  /// answer on web, where `Platform` throws.
  static bool get replaySupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool _shareLogs = _defaultShareLogs;
  bool _shareReplay = _defaultShareReplay;
  bool _noticeShown = _defaultNoticeShown;

  bool get shareLogs => _shareLogs;

  /// Whether a replay of the seconds before a failure goes with it.
  ///
  /// §1's "second switch of its own", and subordinate to [shareLogs] rather
  /// than independent of it: with sharing off the SDK is not running, so
  /// nothing is captured either, and there would be nothing for a replay to be
  /// attached to in any case. The Diagnostics screen leaves this row out in
  /// that state rather than showing a control that does nothing.
  ///
  /// On, this is what the user is consenting to: a continuously recorded,
  /// masked buffer of the screen, uploaded only when something fails. See
  /// [_defaultShareReplay].
  bool get shareReplay => _shareReplay;

  /// Whether §1's one-time notice has been put in front of this user.
  ///
  /// False on a fresh install, and false for everyone already running the app
  /// when this shipped - which is exactly §1's "once more for existing users
  /// after the update that carries this", with no second flag and no version
  /// comparison. The key is written the first time the notice is raised and
  /// never read again after that.
  ///
  /// Defaults to false, so a store that will not open means the notice is
  /// shown again rather than skipped. Neither a missing notice nor a failed
  /// read can enable sharing.
  bool get noticeShown => _noticeShown;

  @override
  void readFrom(PrefsReader reader) {
    _shareLogs = reader.or(_shareLogsKey, _defaultShareLogs);
    _shareReplay = reader.or(_replayKey, _defaultShareReplay);
    _noticeShown = reader.or(_noticeShownKey, _defaultNoticeShown);
    reader.report('[Diagnostics]');
  }

  /// A failed preference read cannot authorize recording or transmission.
  @override
  void onLoadFailed(Object error, StackTrace stack) {
    _shareLogs = false;
    _shareReplay = false;
    LogService.warn(
      '[Diagnostics] consent could not be read; sharing remains off: '
      '${error.runtimeType}',
    );
  }

  @override
  void resetFields() {
    _shareLogs = _defaultShareLogs;
    _shareReplay = _defaultShareReplay;
    _noticeShown = _defaultNoticeShown;
  }

  /// Applies the choice to this object and persists it, in that order.
  ///
  /// Listeners fire before the write lands, which is deliberate and is what
  /// `persistSetting` exists for: the switch stays where the user put it and
  /// `Telemetry` starts or stops from the listener, whether or not the disk
  /// agreed. A write that does not stick is one line in the log, #120.
  ///
  /// Starting and stopping the SDK is **not** done here. `Telemetry` listens,
  /// so the dependency runs one way - telemetry knows about the switch, the
  /// switch knows nothing about Sentry - and so this stays testable without
  /// the SDK.
  Future<void> setShareLogs(bool value) async {
    if (value == _shareLogs) return;
    _shareLogs = value;
    notifyListeners();
    await persistSetting(
      'share logs with developers',
      (prefs) => prefs.setBool(_shareLogsKey, value),
    );
  }

  /// Applies the replay choice to this object and persists it.
  ///
  /// The same shape as [setShareLogs], and for the same reason - but what
  /// `Telemetry` does with the notification differs: there is no app-facing
  /// pause API in this major, so a replay sample rate can only be changed by
  /// bringing the SDK down and up again. `Telemetry._reconcile` owns that;
  /// this still knows nothing about Sentry.
  Future<void> setShareReplay(bool value) async {
    if (value == _shareReplay) return;
    _shareReplay = value;
    notifyListeners();
    await persistSetting(
      'send a replay with a failure',
      (prefs) => prefs.setBool(_replayKey, value),
    );
  }

  /// Records that the notice has been seen, so it never appears again.
  ///
  /// Called when it is raised rather than when it is answered. §1: the app is
  /// usable behind it and dismissing it is the same as **Got it**, so there is
  /// no answer to wait for - and a notice that only counts as shown once
  /// somebody taps a button is a notice that comes back forever for anyone who
  /// swipes it away.
  ///
  /// No listeners are notified. Nothing on screen is drawn from this, and the
  /// one thing that reads it has already read it by the time this runs -
  /// notifying would rebuild the tree underneath a sheet that is opening.
  Future<void> markNoticeShown() async {
    if (_noticeShown) return;
    _noticeShown = true;
    await persistSetting(
      'the diagnostics notice has been shown',
      (prefs) => prefs.setBool(_noticeShownKey, true),
    );
  }
}

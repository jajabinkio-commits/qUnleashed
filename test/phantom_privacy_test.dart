import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qunleashed/services/notifications/push_service.dart';
import 'package:qunleashed/services/telemetry/settings.dart';
import 'package:qunleashed/services/telemetry/telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'telemetry_sinks.dart';
import 'unopenable_prefs.dart';

class _Messaging implements FirebaseMessaging {
  final calls = <String>[];
  @override
  Future<void> setAutoInitEnabled(bool enabled) async =>
      calls.add('auto:$enabled');
  @override
  Future<void> deleteToken() async => calls.add('deleteToken');
  @override
  Future<void> subscribeToTopic(String topic) async =>
      calls.add('subscribe:$topic');
  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      calls.add('unsubscribe:$topic');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Simulated preference/SDK boundaries. Native APNs and iOS Keychain are not
/// exercised by these tests. No Firebase credentials or network are used.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(resetTelemetrySinks);

  test('legacy log/replay choices are not PHANTOM consent', () async {
    SharedPreferences.setMockInitialValues({
      'diagnostics.share_logs': true,
      'diagnostics.share_replay': true,
      'diagnostics.notice_shown': true,
    });
    final settings = DiagnosticsSettings();
    await settings.load();
    expect(settings.shareLogs, isFalse);
    expect(settings.shareReplay, isFalse);
    expect(settings.noticeShown, isFalse);
  });

  test(
    'fresh install with a real-shaped DSN never initializes the SDK',
    () async {
      var inits = 0;
      final settings = DiagnosticsSettings();
      final telemetry = Telemetry(
        settings: settings,
        dsn: 'https://example@o1.ingest.sentry.io/1',
        init: (_) async => inits++,
        shutdown: () async {},
      );
      await telemetry.start();
      expect(inits, 0);
      expect(telemetry.running, isFalse);
      expect(settings.shareReplay, isFalse);
    },
  );

  test('unreadable preferences cannot authorize reporting', () async {
    useUnopenablePrefs();
    var inits = 0;
    final settings = DiagnosticsSettings();
    final telemetry = Telemetry(
      settings: settings,
      dsn: 'https://example@o1.ingest.sentry.io/1',
      init: (_) async => inits++,
      shutdown: () async {},
    );
    await telemetry.start();
    expect(settings.loaded, isFalse);
    expect(settings.shareLogs, isFalse);
    expect(settings.shareReplay, isFalse);
    expect(inits, 0);
  });

  test('log consent does not grant screen replay consent', () async {
    SharedPreferences.setMockInitialValues({
      'phantom.diagnostics.share_logs.v1': true,
    });
    final settings = DiagnosticsSettings();
    await settings.load();
    expect(settings.shareLogs, isTrue);
    expect(settings.shareReplay, isFalse);
  });

  group('push consent', () {
    late _Messaging messaging;
    late PushService service;
    int initializations = 0;
    setUp(() {
      initializations = 0;
      messaging = _Messaging();
      service = PushService.forTest(
        messaging: messaging,
        initialize: () async {
          initializations++;
        },
      );
    });

    test(
      'fresh startup never initializes Firebase, permission or token path',
      () async {
        await service.start();
        expect(initializations, 0);
        expect(messaging.calls, isEmpty);
        expect(await service.isAppReleasesEnabled(), isFalse);
        expect(await service.isFirmwareReleasesEnabled(), isFalse);
      },
    );

    test('legacy enabled preferences are ignored', () async {
      SharedPreferences.setMockInitialValues({
        'push.app_releases_enabled': true,
        'push.notifications_enabled': true,
      });
      await service.start();
      expect(initializations, 0);
      expect(messaging.calls, isEmpty);
    });

    test('malformed consent is off', () async {
      SharedPreferences.setMockInitialValues({
        'phantom.push.app_releases_enabled.v1': 'true',
        'phantom.push.notifications_enabled.v1': 1,
      });
      await service.start();
      expect(initializations, 0);
      expect(messaging.calls, isEmpty);
    });

    test('unreadable preferences never initialize Firebase', () async {
      useUnopenablePrefs();
      await service.start();
      expect(initializations, 0);
      expect(messaging.calls, isEmpty);
    });

    test(
      'explicit choice initializes once and subscribes only selected category',
      () async {
        await service.setAppReleasesEnabled(true);
        await service.start();
        expect(initializations, 1);
        expect(messaging.calls, contains('subscribe:app_release'));
        expect(messaging.calls, isNot(contains('subscribe:unl_release')));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('phantom.push.app_releases_enabled.v1'), isTrue);
      },
    );

    test(
      'revoking last category disables token refresh and deletes token',
      () async {
        await service.setAppReleasesEnabled(true);
        messaging.calls.clear();
        await service.setAppReleasesEnabled(false);
        expect(messaging.calls.first, 'auto:false');
        expect(messaging.calls, contains('unsubscribe:app_release'));
        expect(messaging.calls.last, 'deleteToken');
        messaging.calls.clear();
        await service.start();
        expect(
          messaging.calls,
          isEmpty,
          reason: 'no token churn while disabled',
        );
      },
    );

    test('dev preference alone cannot start push', () async {
      await service.setAppDevEnabled(true);
      expect(initializations, 0);
      expect(messaging.calls, isEmpty);
    });

    test(
      'revocation during native initialization cannot enable automatic tokens',
      () async {
        final pending = Completer<void>();
        final entered = Completer<void>();
        service = PushService.forTest(
          messaging: messaging,
          initialize: () {
            entered.complete();
            return pending.future;
          },
        );
        final enabling = service.setAppReleasesEnabled(true);
        await entered.future;
        final disabling = service.setAppReleasesEnabled(false);
        await pumpEventQueue();
        pending.complete();
        await Future.wait([enabling, disabling]);
        expect(messaging.calls, isNot(contains('auto:true')));
        expect(messaging.calls, isNot(contains('subscribe:app_release')));
      },
    );
  });
}

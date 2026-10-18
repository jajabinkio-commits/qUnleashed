import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/persist.dart';

import '../localization/l10n.dart';
import '../logging.dart';
import 'firebase_options.dart';
import 'notification_center.dart';
import 'push_intent.dart';

class PushTopics {
  static const appRelease = 'app_release';
  static const appDev = 'app_dev';
  static const unlRelease = 'unl_release';
  static const ofwRelease = 'ofw_release';
  static const unlDev = 'unl_dev';
  static const ofwDev = 'ofw_dev';

  static const app = [appRelease];
  static const release = [unlRelease, ofwRelease];
  static const dev = [unlDev, ofwDev];
  static const all = [...app, appDev, ...release, ...dev];
}

class PushService {
  PushService._();

  @visibleForTesting
  PushService.forTest({
    required FirebaseMessaging messaging,
    required Future<void> Function() initialize,
  }) : _testMessaging = messaging,
       _testInitialize = initialize;

  FirebaseMessaging? _testMessaging;
  Future<void> Function()? _testInitialize;
  FirebaseMessaging get _messaging =>
      _testMessaging ?? FirebaseMessaging.instance;
  bool get _supported => _testInitialize != null || isSupported;
  final Map<String, bool> _choices = {};
  Future<void> _chain = Future.value();
  static final PushService instance = PushService._();

  static const _prefAppReleases = 'phantom.push.app_releases_enabled.v1';
  static const _prefAppDev = 'phantom.push.app_dev_enabled.v1';
  static const _prefEnabled = 'phantom.push.notifications_enabled.v1';
  static const _prefDevUpdates = 'phantom.push.dev_updates_enabled.v1';
  static const _androidChannelId = 'firmware_updates';

  bool _started = false;
  bool _enabled = false;
  static bool _unavailable = false;

  final ValueNotifier<PushIntent?> taps = ValueNotifier<PushIntent?>(null);

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static bool get isUnavailable => _unavailable;

  /// No Firebase initialization, permission prompt or token registration until
  /// a PHANTOM notification category has been explicitly enabled.
  Future<void> start() => _reconcile();

  Future<void> _reconcile() {
    _chain = _chain.then((_) => _sync()).catchError((Object error) {
      _unavailable = true;
      LogService.warn(
        '[Push] notification settings could not be applied: ${error.runtimeType}',
      );
    });
    return _chain;
  }

  Future<void> _sync() async {
    if (!_supported) return;
    final enabled =
        await isAppReleasesEnabled() || await isFirmwareReleasesEnabled();
    if (!enabled && (!_started || !_enabled)) return;
    if (!enabled) {
      await _messaging.setAutoInitEnabled(false);
      await _applySubscriptions();
      await _messaging.deleteToken();
      _enabled = false;
      return;
    }
    if (!_started) {
      if (_testInitialize case final initialize?) {
        await initialize();
      } else {
        await _initializePlatform();
      }
      _started = true;
    }
    // Consent may have been revoked while the native permission sheet was up.
    if (!(await isAppReleasesEnabled() || await isFirmwareReleasesEnabled())) {
      await _messaging.setAutoInitEnabled(false);
      await _messaging.deleteToken();
      _enabled = false;
      return;
    }
    _enabled = true;
    await _messaging.setAutoInitEnabled(true);
    await _applySubscriptions();
    _unavailable = false;
  }

  Future<void> _initializePlatform() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _messaging.setAutoInitEnabled(false);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationCenter.instance.initialize(
      onNotificationTap: (payload) => _dispatch(PushIntent.decode(payload)),
    );
    await _ensureAndroidChannel();
    await _messaging.requestPermission(alert: true, badge: false, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    _open(await _messaging.getInitialMessage());
  }

  Future<bool> _readChoice(String key) async {
    if (_choices[key] case final choice?) return choice;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.get(key) == true;
    } catch (error) {
      LogService.warn(
        '[Push] consent could not be read; notifications remain off: ${error.runtimeType}',
      );
      return false;
    }
  }

  Future<void> _setChoice(String key, bool enabled) async {
    _choices[key] = enabled;
    await persistSetting('notification consent', (prefs) async {
      if (!await prefs.setBool(key, enabled)) {
        throw StateError('Notification consent was not saved');
      }
    });
    await _reconcile();
  }

  void _open(RemoteMessage? message) {
    if (message == null) return;
    _dispatch(PushIntent.fromData(message.data));
  }

  void _dispatch(PushIntent? intent) {
    if (intent != null) taps.value = intent;
  }

  static int _notificationId(RemoteMessage message, PushIntent? intent) {
    final seed = intent == null
        ? message.hashCode
        : Object.hash(intent.type, intent.entry, intent.version);
    return seed & 0x7fffffff;
  }

  Future<bool> isAppReleasesEnabled() => _readChoice(_prefAppReleases);
  Future<void> setAppReleasesEnabled(bool enabled) =>
      _setChoice(_prefAppReleases, enabled);
  Future<bool> isAppDevEnabled() => _readChoice(_prefAppDev);
  Future<void> setAppDevEnabled(bool enabled) =>
      _setChoice(_prefAppDev, enabled);
  Future<bool> isFirmwareReleasesEnabled() => _readChoice(_prefEnabled);
  Future<void> setFirmwareReleasesEnabled(bool enabled) =>
      _setChoice(_prefEnabled, enabled);
  Future<bool> isFirmwareDevEnabled() => _readChoice(_prefDevUpdates);
  Future<void> setFirmwareDevEnabled(bool enabled) =>
      _setChoice(_prefDevUpdates, enabled);

  Future<void> _applySubscriptions() async {
    final messaging = _messaging;
    final appEnabled = await isAppReleasesEnabled();
    final appDevEnabled = await isAppDevEnabled();
    final enabled = await isFirmwareReleasesEnabled();
    final devEnabled = await isFirmwareDevEnabled();

    final active = <String>{};
    if (appEnabled) {
      active.addAll(PushTopics.app);
      if (appDevEnabled) active.add(PushTopics.appDev);
    }
    if (enabled) {
      active.addAll(PushTopics.release);
      if (devEnabled) active.addAll(PushTopics.dev);
    }

    for (final topic in PushTopics.all) {
      if (active.contains(topic)) {
        await messaging.subscribeToTopic(topic);
      } else {
        await messaging.unsubscribeFromTopic(topic);
      }
    }
  }

  Future<void> _ensureAndroidChannel() async {
    if (!Platform.isAndroid) return;
    await NotificationCenter.instance.plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _androidChannelId,
            l10n.notificationChannelFirmwareUpdates,
            description: l10n.notificationChannelFirmwareUpdatesDescription,
            importance: Importance.high,
          ),
        );
  }

  Future<void> _showForeground(RemoteMessage message) async {
    if (!(await isAppReleasesEnabled() || await isFirmwareReleasesEnabled())) {
      return;
    }
    final notification = message.notification;
    final title = notification?.title ?? l10n.notificationUpdateFallbackTitle;
    final body = notification?.body ?? '';
    final intent = PushIntent.fromData(message.data);

    await NotificationCenter.instance.plugin.show(
      id: _notificationId(message, intent),
      title: title,
      body: body,
      payload: intent?.encode(),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          l10n.notificationChannelFirmwareUpdates,
          channelDescription:
              l10n.notificationChannelFirmwareUpdatesDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

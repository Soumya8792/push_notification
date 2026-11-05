import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_push_kit_config.dart';
import 'push_notification_tap.dart';

// getToken/onTokenRefresh/deleteToken are deprecated in firebase_messaging 17
// in favour of FID registration, but FCM tokens are still what the Firebase
// console test sender and the HTTP v1 `token` target use. FID APIs are exposed
// alongside them (register/onRegistered) for projects that migrate.
// ignore_for_file: deprecated_member_use

/// Default background handler: background isolates need their own Firebase
/// instance before any FCM work can happen.
@pragma('vm:entry-point')
Future<void> fcmPushKitDefaultBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
}

/// One entry point for Firebase Cloud Messaging on Android and iOS:
/// permissions, token, foreground display, topics and tap/deep-link handling.
class FcmPushKit {
  FcmPushKit._();
  static final FcmPushKit instance = FcmPushKit._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<PushNotificationTap> _tapController =
      StreamController<PushNotificationTap>.broadcast();
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  FcmPushKitConfig _config = const FcmPushKitConfig();
  bool _initialized = false;
  bool _initialTapConsumed = false;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  bool get isInitialized => _initialized;

  /// Taps on notifications while the app is running (foreground or
  /// background). For a tap that launched the app, use [getInitialTap].
  Stream<PushNotificationTap> get onNotificationTap => _tapController.stream;

  /// Messages received while the app is in the foreground.
  Stream<RemoteMessage> get onForegroundMessage => _messageController.stream;

  /// New FCM tokens. Send each one to your backend.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// Firebase Installation IDs (FIDs) for FID-based direct send, emitted after
  /// [register]. Alternative to FCM tokens.
  Stream<String> get onRegistered => _fcm.onRegistered;

  /// Registers this app instance for FID-based direct send; see [onRegistered].
  Future<void> register() => _fcm.register();

  /// Reverses [register], e.g. on logout.
  Future<void> unregister() => _fcm.unregister();

  /// Initializes Firebase (when [firebaseOptions] is given or no app exists
  /// yet) and FCM. Call once in `main()` before `runApp`.
  Future<void> initialize({
    FirebaseOptions? firebaseOptions,
    FcmPushKitConfig config = const FcmPushKitConfig(),
  }) async {
    if (_initialized) return;
    _config = config;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
    }

    FirebaseMessaging.onBackgroundMessage(
      config.backgroundHandler ?? fcmPushKitDefaultBackgroundHandler,
    );

    await _initLocalNotifications();

    // iOS shows foreground notifications natively through these options, so
    // the local-notification fallback below is only needed on Android.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: config.showForegroundNotifications,
      badge: config.showForegroundNotifications,
      sound: config.showForegroundNotifications,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) =>
          _emitTap(message.data, TapSource.background, message.messageId),
    );
    _fcm.onTokenRefresh.listen((token) => _log('FCM token refreshed: $token'));

    _initialized = true;

    if (config.requestPermissionOnInit) await requestPermission();
    for (final topic in config.topics) {
      await subscribeToTopic(topic);
    }
  }

  /// Shows the system permission prompt (iOS, Android 13+). Returns true when
  /// notifications are allowed.
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log('Notification permission: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Current permission state without prompting the user.
  Future<AuthorizationStatus> getPermissionStatus() async =>
      (await _fcm.getNotificationSettings()).authorizationStatus;

  /// Current FCM registration token, or null if unavailable (e.g. iOS
  /// simulator without APNs, or no network).
  Future<String?> getToken() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
        if (await _waitForApnsToken() == null) {
          _log('APNs token not available yet; cannot fetch FCM token.');
          return null;
        }
      }
      final token = await _fcm.getToken();
      _log('FCM token: $token');
      return token;
    } catch (e) {
      _log('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Invalidates the current token, e.g. on logout.
  Future<void> deleteToken() => _fcm.deleteToken();

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    _log('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    _log('Unsubscribed from topic: $topic');
  }

  /// The notification tap that launched the app from a terminated state, if
  /// any. Returns a value at most once; call it after the first frame.
  Future<PushNotificationTap?> getInitialTap() async {
    if (_initialTapConsumed) return null;
    _initialTapConsumed = true;

    final message = await _fcm.getInitialMessage();
    if (message != null) {
      return _buildTap(message.data, TapSource.terminated, message.messageId);
    }

    // A foreground local notification tapped after the app was killed.
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null) {
      final data = _decodePayload(payload);
      if (data != null) return _buildTap(data, TapSource.terminated, null);
    }
    return null;
  }

  /// Shows a notification from the app itself (no server involved). Tapping
  /// it is delivered through [onNotificationTap] like a push notification, so
  /// [data] can carry a route, e.g. `{'route': '/details', 'id': '42'}`.
  Future<void> showNotification({
    String? title,
    String? body,
    Map<String, dynamic> data = const {},
    int? id,
  }) async {
    await _localNotifications.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _config.androidChannelId,
          _config.androidChannelName,
          channelDescription: _config.androidChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: _config.androidSmallIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  Future<void> _initLocalNotifications() async {
    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(_config.androidSmallIcon),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final data = _decodePayload(payload);
        if (data != null) _emitTap(data, TapSource.foreground, null);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _config.androidChannelId,
            _config.androidChannelName,
            description: _config.androidChannelDescription,
            importance: Importance.max,
          ),
        );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    _log('Foreground message: ${message.notification?.title} ${message.data}');
    _messageController.add(message);

    final notification = message.notification;
    if (!_config.showForegroundNotifications || notification == null) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await showNotification(
      id: message.messageId?.hashCode ?? message.hashCode,
      title: notification.title,
      body: notification.body,
      data: message.data,
    );
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) return apnsToken;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  PushNotificationTap _buildTap(
    Map<String, dynamic> data,
    TapSource source,
    String? messageId,
  ) => PushNotificationTap(
    data: data,
    source: source,
    messageId: messageId,
    routeKey: _config.routeKey,
  );

  void _emitTap(Map<String, dynamic> data, TapSource source, String? id) {
    final tap = _buildTap(data, source, id);
    _log('Notification tapped: $tap');
    _tapController.add(tap);
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    try {
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (e) {
      _log('Could not decode notification payload: $e');
      return null;
    }
  }

  void _log(String message) {
    if (_config.enableLogs && kDebugMode) debugPrint('[FcmPushKit] $message');
  }
}

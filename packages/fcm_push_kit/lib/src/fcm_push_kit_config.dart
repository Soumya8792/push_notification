import 'package:firebase_messaging/firebase_messaging.dart';

/// App-specific settings for [FcmPushKit]. Every field has a sensible default,
/// so `const FcmPushKitConfig()` is enough for most apps.
class FcmPushKitConfig {
  const FcmPushKitConfig({
    this.androidChannelId = 'high_importance_channel',
    this.androidChannelName = 'High Importance Notifications',
    this.androidChannelDescription =
        'Channel used for high priority push notifications.',
    this.androidSmallIcon = '@mipmap/ic_launcher',
    this.showForegroundNotifications = true,
    this.requestPermissionOnInit = true,
    this.routeKey = 'route',
    this.topics = const [],
    this.backgroundHandler,
    this.enableLogs = false,
  });

  /// Android notification channel. Must match the
  /// `com.google.firebase.messaging.default_notification_channel_id`
  /// meta-data in AndroidManifest.xml.
  final String androidChannelId;
  final String androidChannelName;
  final String androidChannelDescription;

  /// Drawable/mipmap used as the small icon for foreground notifications on
  /// Android. Prefer a white, transparent drawable in production.
  final String androidSmallIcon;

  /// Show a heads-up/banner when a message arrives while the app is open.
  final bool showForegroundNotifications;

  /// Ask for notification permission during [FcmPushKit.initialize]. Set to
  /// false to ask later via [FcmPushKit.requestPermission] (e.g. after an
  /// onboarding screen).
  final bool requestPermissionOnInit;

  /// Key in the FCM `data` payload that holds the in-app route to open when
  /// the notification is tapped, e.g. `{"route": "/details", "id": "42"}`.
  final String routeKey;

  /// Topics to subscribe to right after initialization.
  final List<String> topics;

  /// Handler for messages received while the app is in the background or
  /// terminated. Must be a top-level or static function annotated with
  /// `@pragma('vm:entry-point')`. When null, a default handler that only
  /// initializes Firebase is used.
  final BackgroundMessageHandler? backgroundHandler;

  /// Print debug logs (token, incoming messages, taps) in debug builds.
  final bool enableLogs;
}

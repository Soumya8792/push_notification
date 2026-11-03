/// Reusable Firebase Cloud Messaging setup for Flutter apps on Android and iOS.
library;

export 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
export 'package:firebase_messaging/firebase_messaging.dart'
    show RemoteMessage, RemoteNotification, BackgroundMessageHandler;

export 'src/fcm_push_kit.dart';
export 'src/fcm_push_kit_config.dart';
export 'src/push_notification_tap.dart';

# fcm_push_kit

Reusable Firebase Cloud Messaging (FCM) setup for Flutter apps on **Android and iOS**.
One `initialize()` call handles permissions, foreground display, tokens, topics and
notification taps (foreground / background / terminated) with deep-link routes.

## Install

Add it as a git dependency in the app's `pubspec.yaml`:

```yaml
dependencies:
  fcm_push_kit:
    git:
      url: https://github.com/Soumya8792/push_notification.git
      path: packages/fcm_push_kit
      ref: main            # pin a tag (e.g. fcm_push_kit-v0.1.0) for production
```

The app also needs `firebase_core` for the generated `firebase_options.dart`.

## Firebase setup (once per app)

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=<firebase-project-id> --platforms=android,ios
```

## Usage

```dart
import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmPushKit.instance.initialize(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    config: const FcmPushKitConfig(topics: ['all'], enableLogs: true),
  );

  FcmPushKit.instance.onNotificationTap.listen((tap) {
    final location = tap.location;          // e.g. /details?id=42
    if (location != null) router.go(location);
  });
  FcmPushKit.instance.onTokenRefresh.listen(sendTokenToBackend);

  runApp(const MyApp());
}

// After the first frame — handles a tap that launched the app:
final tap = await FcmPushKit.instance.getInitialTap();
```

Payload contract: put the in-app route under `data.route`; other `data` keys become
query parameters. `{"route": "/details", "id": "42"}` → `/details?id=42`.

## Native setup checklist

**Android** (`android/app/build.gradle.kts`): enable core library desugaring
(required by `flutter_local_notifications`), `minSdk = 24`, and add in
`AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

**iOS**: Push Notifications + Background Modes → Remote notifications capabilities,
upload an APNs Auth Key (.p8) in Firebase console → Cloud Messaging, and in
`AppDelegate.didFinishLaunchingWithOptions` set
`UNUserNotificationCenter.current().delegate = self`. Test on a real iPhone —
Simulator APNs support is limited and unreliable for FCM.

See the POC document in the repo root `docs/` for the full walkthrough.

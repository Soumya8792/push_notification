import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await fcmPushKitDefaultBackgroundHandler(message);
  debugPrint('Background message: ${message.messageId} ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FcmPushKit.instance.initialize(
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
      config: const FcmPushKitConfig(
        topics: ['all'],
        backgroundHandler: backgroundMessageHandler,
        enableLogs: true,
      ),
    );
    AppRouter.setupNotificationDeepLinkListener();
  } catch (e) {
    debugPrint('Firebase not configured yet: $e. Run `flutterfire configure`.');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!FcmPushKit.instance.isInitialized) return;
      final tap = await FcmPushKit.instance.getInitialTap();
      final location = tap?.location;
      if (location != null) AppRouter.router.go(location);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Push Notification & DeepLink Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}

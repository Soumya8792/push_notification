import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fcm_push_kit/fcm_push_kit.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/details',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'] ?? 'N/A';
          return DetailsScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );

  static void setupNotificationDeepLinkListener() {
    FcmPushKit.instance.onNotificationTap.listen((tap) {
      final location = tap.location;
      if (location != null && rootNavigatorKey.currentContext != null) {
        router.go(location);
      }
    });
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notification & DeepLink Demo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'FCM Push Notification & Deep Link POC',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final token = FcmPushKit.instance.isInitialized
                      ? await FcmPushKit.instance.getToken()
                      : null;
                  debugPrint('FCM TOKEN: $token');
                  if (token != null) {
                    await Clipboard.setData(ClipboardData(text: token));
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(token == null
                            ? 'No FCM token yet. Is Firebase configured?'
                            : 'FCM token copied to clipboard'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.key),
                label: const Text('Copy FCM Token'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final String itemId;
  const DetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details Screen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 70, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Successfully Navigated via Deep Link!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Passed Item ID: $itemId',
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 70, color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Profile Screen (Deep Link Target)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

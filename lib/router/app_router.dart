import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/deep_link_screens.dart';
import '../screens/home_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    // Unknown routes in a payload fall back to home instead of an error page.
    errorBuilder: (context, state) => const HomeScreen(),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/details',
        builder: (context, state) =>
            DetailsScreen(params: state.uri.queryParameters),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            ProfileScreen(params: state.uri.queryParameters),
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

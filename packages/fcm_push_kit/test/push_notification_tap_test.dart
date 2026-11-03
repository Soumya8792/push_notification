import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PushNotificationTap tap(Map<String, dynamic> data, {String routeKey = 'route'}) =>
      PushNotificationTap(
        data: data,
        source: TapSource.background,
        routeKey: routeKey,
      );

  test('builds location from route and extra data', () {
    expect(tap({'route': '/details', 'id': '42'}).location, '/details?id=42');
  });

  test('route without extra data has no query string', () {
    expect(tap({'route': '/profile'}).location, '/profile');
  });

  test('keeps query parameters already in the route', () {
    expect(
      tap({'route': '/details?tab=info', 'id': '7'}).location,
      '/details?tab=info&id=7',
    );
  });

  test('returns null when route is missing or empty', () {
    expect(tap({'id': '42'}).location, isNull);
    expect(tap({'route': ''}).location, isNull);
  });

  test('honours a custom route key', () {
    expect(
      tap({'screen': '/orders', 'orderId': '9'}, routeKey: 'screen').location,
      '/orders?orderId=9',
    );
  });
}

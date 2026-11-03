/// App state the user tapped the notification from.
enum TapSource { foreground, background, terminated }

/// A notification the user tapped, with its FCM `data` payload.
class PushNotificationTap {
  const PushNotificationTap({
    required this.data,
    required this.source,
    this.messageId,
    this.routeKey = 'route',
  });

  final Map<String, dynamic> data;
  final TapSource source;
  final String? messageId;
  final String routeKey;

  /// Raw route value from the payload, e.g. `/details`.
  String? get route {
    final value = data[routeKey];
    return value is String && value.isNotEmpty ? value : null;
  }

  /// Route plus every other data entry as query parameters, ready for
  /// `GoRouter.go`, e.g. `{"route": "/details", "id": "42"}` → `/details?id=42`.
  /// Query parameters already present in the route are kept.
  String? get location {
    final route = this.route;
    if (route == null) return null;

    final uri = Uri.parse(route);
    final query = <String, String>{
      ...uri.queryParameters,
      for (final entry in data.entries)
        if (entry.key != routeKey && entry.value != null)
          entry.key: entry.value.toString(),
    };
    return uri
        .replace(queryParameters: query.isEmpty ? null : query)
        .toString();
  }

  @override
  String toString() =>
      'PushNotificationTap(source: $source, messageId: $messageId, data: $data)';
}

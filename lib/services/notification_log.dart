import 'dart:async';

import 'package:fcm_push_kit/fcm_push_kit.dart';
import 'package:flutter/foundation.dart';

enum LogEntryType { received, tapped }

class NotificationLogEntry {
  NotificationLogEntry({
    required this.type,
    required this.data,
    this.title,
    this.body,
    this.source,
  }) : time = DateTime.now();

  final LogEntryType type;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final TapSource? source;
  final DateTime time;
}

/// In-memory history of notifications received in the foreground and taps,
/// so they can be checked on screen while testing.
class NotificationLog extends ChangeNotifier {
  NotificationLog._();
  static final NotificationLog instance = NotificationLog._();

  final List<NotificationLogEntry> _entries = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<NotificationLogEntry> get entries => List.unmodifiable(_entries);

  void attach(FcmPushKit kit) {
    _subscriptions
      ..add(kit.onForegroundMessage.listen(addMessage))
      ..add(kit.onNotificationTap.listen(addTap));
  }

  void addMessage(RemoteMessage message) => _add(
    NotificationLogEntry(
      type: LogEntryType.received,
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    ),
  );

  void addTap(PushNotificationTap tap) => _add(
    NotificationLogEntry(
      type: LogEntryType.tapped,
      data: tap.data,
      source: tap.source,
    ),
  );

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  void _add(NotificationLogEntry entry) {
    _entries.insert(0, entry);
    notifyListeners();
  }
}

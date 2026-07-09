import 'local_notification_payload.dart';

enum LocalNotificationRecurrence { none, daily, weekly }

class LocalNotificationSchedule {
  const LocalNotificationSchedule({
    required this.key,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
    this.recurrence = LocalNotificationRecurrence.none,
  });

  final String key;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final LocalNotificationPayload payload;
  final LocalNotificationRecurrence recurrence;

  int get notificationId => stableNotificationId(key);
}

int stableNotificationId(String key) {
  var hash = 0x811c9dc5;

  for (final codeUnit in key.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }

  return hash;
}

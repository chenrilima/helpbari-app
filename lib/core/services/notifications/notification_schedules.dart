import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';

abstract final class NotificationSchedules {
  static LocalNotificationSchedule dailyReminder({
    required NotificationSource source,
    required String entityId,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) {
    return reminder(
      source: source,
      entityId: entityId,
      title: title,
      body: body,
      scheduledAt: _todayAt(hour: hour, minute: minute),
      recurrence: LocalNotificationRecurrence.daily,
    );
  }

  static LocalNotificationSchedule reminder({
    required NotificationSource source,
    required String entityId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    LocalNotificationRecurrence recurrence = LocalNotificationRecurrence.none,
  }) {
    final payload = LocalNotificationPayload(
      source: source,
      entityId: entityId,
    );

    return LocalNotificationSchedule(
      key: notificationKey(payload.source, payload.entityId),
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      recurrence: recurrence,
      payload: payload,
    );
  }

  static DateTime _todayAt({required int hour, required int minute}) {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

String notificationKey(NotificationSource source, String entityId) {
  return '${source.name}:$entityId';
}

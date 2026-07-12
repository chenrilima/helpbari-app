import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';

abstract final class NotificationSchedules {
  static LocalNotificationSchedule dailyReminder({
    required NotificationSource source,
    required String userId,
    required String entityId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    return reminder(
      source: source,
      userId: userId,
      entityId: entityId,
      title: title,
      body: body,
      scheduledAt: _todayAt(now: now, hour: hour, minute: minute),
      recurrence: LocalNotificationRecurrence.daily,
    );
  }

  static LocalNotificationSchedule reminder({
    required NotificationSource source,
    required String userId,
    required String entityId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    LocalNotificationRecurrence recurrence = LocalNotificationRecurrence.none,
  }) {
    final payload = LocalNotificationPayload(
      source: source,
      entityId: entityId,
      userId: userId,
    );

    return LocalNotificationSchedule(
      key: notificationKey(userId, payload.source, payload.entityId),
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      recurrence: recurrence,
      payload: payload,
    );
  }

  static DateTime _todayAt({
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

String notificationKey(
  String userId,
  NotificationSource source,
  String entityId,
) {
  return '$userId:${source.name}:$entityId';
}

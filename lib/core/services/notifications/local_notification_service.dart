import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';

abstract interface class LocalNotificationService {
  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<void> scheduleOnce(LocalNotificationSchedule schedule);

  Future<void> scheduleRecurring(LocalNotificationSchedule schedule);

  Future<void> update(LocalNotificationSchedule schedule);

  Future<void> reschedule(Iterable<LocalNotificationSchedule> schedules);

  Future<void> cancel(String key);

  Future<void> cancelPayload(LocalNotificationPayload payload);

  Future<void> cancelAll();
}

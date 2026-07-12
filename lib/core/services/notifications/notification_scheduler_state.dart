import 'local_notification_service.dart';

class NotificationSchedulerState {
  const NotificationSchedulerState({
    this.scheduled = 0,
    this.failures = 0,
    this.lastRestoreAt,
    this.permission = NotificationPermissionState.unknown,
    this.timeZone,
    this.userId,
  });

  final int scheduled;
  final int failures;
  final DateTime? lastRestoreAt;
  final NotificationPermissionState permission;
  final String? timeZone;
  final String? userId;
}

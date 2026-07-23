import '../../../core/services/services.dart';
import '../domain/entities/entities.dart';

class AppointmentReminderService {
  const AppointmentReminderService({
    required NotificationScheduler scheduler,
    required String userId,
  }) : _scheduler = scheduler,
       _userId = userId;

  final NotificationScheduler _scheduler;
  final String _userId;

  Future<void> applyAfterCommit(Appointment appointment) =>
      cancel(appointment.id);

  Future<void> cancel(String appointmentId) {
    return _scheduler.cancel(
      LocalNotificationPayload(
        source: NotificationSource.appointment,
        entityId: appointmentId,
        userId: _userId,
      ),
    );
  }
}

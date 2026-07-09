import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class AppointmentReminderService {
  const AppointmentReminderService({
    required SettingsUseCases settingsUseCases,
    required LocalNotificationService notifications,
  }) : _settingsUseCases = settingsUseCases,
       _notifications = notifications;

  final SettingsUseCases _settingsUseCases;
  final LocalNotificationService _notifications;

  Future<void> scheduleIfEnabled(Appointment appointment) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.appointmentRemindersEnabled || !appointment.isUpcoming) {
      return;
    }

    await _notifications.scheduleOnce(_appointmentSchedule(appointment));
  }

  Future<void> rescheduleIfEnabled(Appointment appointment) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.appointmentRemindersEnabled || !appointment.isUpcoming) {
      return;
    }

    await _notifications.update(_appointmentSchedule(appointment));
  }

  Future<void> cancel(String appointmentId) {
    return _notifications.cancelPayload(
      LocalNotificationPayload(
        source: NotificationSource.appointment,
        entityId: appointmentId,
      ),
    );
  }

  LocalNotificationSchedule _appointmentSchedule(Appointment appointment) {
    return NotificationSchedules.reminder(
      source: NotificationSource.appointment,
      entityId: appointment.id,
      title: 'Consulta agendada',
      body: appointment.location == null
          ? appointment.title
          : '${appointment.title} em ${appointment.location}',
      scheduledAt: appointment.date.value,
    );
  }
}

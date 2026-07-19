import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class AppointmentReminderService {
  const AppointmentReminderService({
    required SettingsUseCases settingsUseCases,
    required NotificationScheduler scheduler,
    required String userId,
  }) : _settingsUseCases = settingsUseCases,
       _scheduler = scheduler,
       _userId = userId;

  final SettingsUseCases _settingsUseCases;
  final NotificationScheduler _scheduler;
  final String _userId;

  Future<void> scheduleIfEnabled(Appointment appointment) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.appointmentRemindersEnabled || !appointment.isUpcoming) {
      return;
    }

    await _scheduler.schedule(_appointmentSchedule(appointment));
  }

  Future<void> rescheduleIfEnabled(Appointment appointment) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.appointmentRemindersEnabled || !appointment.isUpcoming) {
      await cancel(appointment.id);
      return;
    }

    await _scheduler.schedule(_appointmentSchedule(appointment));
  }

  Future<void> applyAfterCommit(Appointment appointment) =>
      appointment.isScheduled
      ? rescheduleIfEnabled(appointment)
      : cancel(appointment.id);

  Future<void> cancel(String appointmentId) {
    return _scheduler.cancel(
      LocalNotificationPayload(
        source: NotificationSource.appointment,
        entityId: appointmentId,
        userId: _userId,
      ),
    );
  }

  LocalNotificationSchedule _appointmentSchedule(Appointment appointment) {
    return NotificationSchedules.reminder(
      source: NotificationSource.appointment,
      userId: _userId,
      entityId: appointment.id,
      title: 'Agendamento confirmado',
      body: appointment.location == null
          ? appointment.title
          : '${appointment.title} em ${appointment.location}',
      scheduledAt: appointment.date.value,
    );
  }

  LocalNotificationSchedule scheduleFor(Appointment appointment) =>
      _appointmentSchedule(appointment);
}

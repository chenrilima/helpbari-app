import '../../../core/services/services.dart';
import '../../appointments/application/appointment_reminder_service.dart';
import '../../appointments/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class SettingsReminderSyncService {
  SettingsReminderSyncService({
    required AppointmentUseCases appointmentUseCases,
    required AppointmentReminderService appointmentReminders,
    required NotificationScheduler scheduler,
    required String userId,
  }) : _appointmentUseCases = appointmentUseCases,
       _appointmentReminders = appointmentReminders,
       _scheduler = scheduler,
       _userId = userId;

  final AppointmentUseCases _appointmentUseCases;
  final AppointmentReminderService _appointmentReminders;
  final NotificationScheduler _scheduler;
  final String _userId;

  Future<bool> applyAfterCommit(AppSettings settings) async {
    await restore(settings);
    return true;
  }

  Future<void> restore(AppSettings settings) async {
    await _scheduler.activateUser(_userId);
    for (final appointment in await _appointmentUseCases.getAll()) {
      await _appointmentReminders.cancel(appointment.id);
    }
  }
}

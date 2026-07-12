import '../../../core/services/services.dart';
import '../../appointments/application/appointment_reminder_service.dart';
import '../../appointments/domain/usecases/use_cases.dart';
import '../../medications/application/medication_reminder_service.dart';
import '../../medications/domain/usecases/use_cases.dart';
import '../../vitamins/application/vitamin_reminder_service.dart';
import '../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../domain/entities/entities.dart';

class SettingsReminderSyncService {
  SettingsReminderSyncService({
    required VitaminUseCases vitaminUseCases,
    required VitaminReminderService vitaminReminders,
    required MedicationUseCases medicationUseCases,
    required MedicationReminderService medicationReminders,
    required AppointmentUseCases appointmentUseCases,
    required AppointmentReminderService appointmentReminders,
    required NotificationScheduler scheduler,
    required String userId,
  }) : _vitaminUseCases = vitaminUseCases,
       _vitaminReminders = vitaminReminders,
       _medicationUseCases = medicationUseCases,
       _medicationReminders = medicationReminders,
       _appointmentUseCases = appointmentUseCases,
       _appointmentReminders = appointmentReminders,
       _scheduler = scheduler,
       _userId = userId;

  final VitaminUseCases _vitaminUseCases;
  final VitaminReminderService _vitaminReminders;
  final MedicationUseCases _medicationUseCases;
  final MedicationReminderService _medicationReminders;
  final AppointmentUseCases _appointmentUseCases;
  final AppointmentReminderService _appointmentReminders;
  final NotificationScheduler _scheduler;
  final String _userId;

  Future<bool> applyAfterCommit(AppSettings settings) async {
    await restore(settings);
    return true;
  }

  Future<void> restore(AppSettings settings) async {
    final schedules = <LocalNotificationSchedule>[];
    if (settings.vitaminRemindersEnabled) {
      schedules.addAll(
        (await _vitaminUseCases.getAll()).map(_vitaminReminders.scheduleFor),
      );
    }
    if (settings.medicationRemindersEnabled) {
      schedules.addAll(
        (await _medicationUseCases.getAll()).map(
          _medicationReminders.scheduleFor,
        ),
      );
    }
    if (settings.appointmentRemindersEnabled) {
      schedules.addAll(
        (await _appointmentUseCases.getAll())
            .where((appointment) => appointment.isUpcoming)
            .map(_appointmentReminders.scheduleFor),
      );
    }
    await _scheduler.restore(userId: _userId, schedules: schedules);
  }
}

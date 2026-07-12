import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class MedicationReminderService {
  const MedicationReminderService({
    required SettingsUseCases settingsUseCases,
    required NotificationScheduler scheduler,
    required ClockService clock,
    required String userId,
  }) : _settingsUseCases = settingsUseCases,
       _scheduler = scheduler,
       _clock = clock,
       _userId = userId;

  final SettingsUseCases _settingsUseCases;
  final NotificationScheduler _scheduler;
  final ClockService _clock;
  final String _userId;

  Future<void> scheduleIfEnabled(Medication medication) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.medicationRemindersEnabled) return;

    await _scheduler.schedule(_medicationSchedule(medication));
  }

  Future<void> rescheduleIfEnabled(Medication medication) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.medicationRemindersEnabled) {
      await cancel(medication.id);
      return;
    }

    await _scheduler.schedule(_medicationSchedule(medication));
  }

  Future<void> cancel(String medicationId) {
    return _scheduler.cancel(
      LocalNotificationPayload(
        source: NotificationSource.medication,
        entityId: medicationId,
        userId: _userId,
      ),
    );
  }

  LocalNotificationSchedule _medicationSchedule(Medication medication) {
    return NotificationSchedules.dailyReminder(
      source: NotificationSource.medication,
      userId: _userId,
      entityId: medication.id,
      title: 'Hora do medicamento',
      body: 'Registre ${medication.formattedName}.',
      hour: medication.scheduleTime.hour,
      minute: medication.scheduleTime.minute,
      now: _clock.now(),
    );
  }

  LocalNotificationSchedule scheduleFor(Medication medication) =>
      _medicationSchedule(medication);
}

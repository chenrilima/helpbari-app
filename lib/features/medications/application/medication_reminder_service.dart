import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class MedicationReminderService {
  const MedicationReminderService({
    required SettingsUseCases settingsUseCases,
    required LocalNotificationService notifications,
  }) : _settingsUseCases = settingsUseCases,
       _notifications = notifications;

  final SettingsUseCases _settingsUseCases;
  final LocalNotificationService _notifications;

  Future<void> scheduleIfEnabled(Medication medication) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.medicationRemindersEnabled) return;

    await _notifications.scheduleRecurring(_medicationSchedule(medication));
  }

  Future<void> rescheduleIfEnabled(Medication medication) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.medicationRemindersEnabled) return;

    await _notifications.update(_medicationSchedule(medication));
  }

  Future<void> cancel(String medicationId) {
    return _notifications.cancelPayload(
      LocalNotificationPayload(
        source: NotificationSource.medication,
        entityId: medicationId,
      ),
    );
  }

  LocalNotificationSchedule _medicationSchedule(Medication medication) {
    return NotificationSchedules.dailyReminder(
      source: NotificationSource.medication,
      entityId: medication.id,
      title: 'Hora do medicamento',
      body: 'Registre ${medication.formattedName}.',
      hour: medication.scheduleTime.hour,
      minute: medication.scheduleTime.minute,
    );
  }
}

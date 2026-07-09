import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class VitaminReminderService {
  const VitaminReminderService({
    required SettingsUseCases settingsUseCases,
    required LocalNotificationService notifications,
  }) : _settingsUseCases = settingsUseCases,
       _notifications = notifications;

  final SettingsUseCases _settingsUseCases;
  final LocalNotificationService _notifications;

  Future<void> scheduleIfEnabled(Vitamin vitamin) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.vitaminRemindersEnabled) return;

    await _notifications.scheduleRecurring(_vitaminSchedule(vitamin));
  }

  Future<void> rescheduleIfEnabled(Vitamin vitamin) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.vitaminRemindersEnabled) return;

    await _notifications.update(_vitaminSchedule(vitamin));
  }

  Future<void> cancel(String vitaminId) {
    return _notifications.cancelPayload(
      LocalNotificationPayload(
        source: NotificationSource.vitamin,
        entityId: vitaminId,
      ),
    );
  }

  LocalNotificationSchedule _vitaminSchedule(Vitamin vitamin) {
    return NotificationSchedules.dailyReminder(
      source: NotificationSource.vitamin,
      entityId: vitamin.id,
      title: 'Hora da vitamina',
      body: 'Registre ${vitamin.formattedName}.',
      hour: vitamin.scheduleTime.hour,
      minute: vitamin.scheduleTime.minute,
    );
  }
}

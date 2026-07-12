import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class VitaminReminderService {
  const VitaminReminderService({
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

  Future<void> scheduleIfEnabled(Vitamin vitamin) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.vitaminRemindersEnabled) return;

    await _scheduler.schedule(_vitaminSchedule(vitamin));
  }

  Future<void> rescheduleIfEnabled(Vitamin vitamin) async {
    final settings = await _settingsUseCases.getSettings();

    if (!settings.vitaminRemindersEnabled) {
      await cancel(vitamin.id);
      return;
    }

    await _scheduler.schedule(_vitaminSchedule(vitamin));
  }

  Future<void> cancel(String vitaminId) {
    return _scheduler.cancel(
      LocalNotificationPayload(
        source: NotificationSource.vitamin,
        entityId: vitaminId,
        userId: _userId,
      ),
    );
  }

  LocalNotificationSchedule _vitaminSchedule(Vitamin vitamin) {
    return NotificationSchedules.dailyReminder(
      source: NotificationSource.vitamin,
      userId: _userId,
      entityId: vitamin.id,
      title: 'Hora da vitamina',
      body: 'Registre ${vitamin.formattedName}.',
      hour: vitamin.scheduleTime.hour,
      minute: vitamin.scheduleTime.minute,
      now: _clock.now(),
    );
  }

  LocalNotificationSchedule scheduleFor(Vitamin vitamin) =>
      _vitaminSchedule(vitamin);
}

import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class VitaminReminderService {
  const VitaminReminderService({
    required SettingsUseCases settingsUseCases,
    required NotificationScheduler scheduler,
    required ClockService clock,
    required String userId,
  }) : _scheduler = scheduler,
       _userId = userId;

  final NotificationScheduler _scheduler;
  final String _userId;

  Future<void> scheduleIfEnabled(Vitamin vitamin) async {
    await cancel(vitamin.id);
  }

  Future<void> rescheduleIfEnabled(Vitamin vitamin) async {
    await cancel(vitamin.id);
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
}

import '../../../core/services/services.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';

class MedicationReminderService {
  const MedicationReminderService({
    required SettingsUseCases settingsUseCases,
    required NotificationScheduler scheduler,
    required ClockService clock,
    required String userId,
  }) : _scheduler = scheduler,
       _userId = userId;

  final NotificationScheduler _scheduler;
  final String _userId;

  Future<void> scheduleIfEnabled(Medication medication) async {
    await cancel(medication.id);
  }

  Future<void> rescheduleIfEnabled(Medication medication) async {
    await cancel(medication.id);
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
}

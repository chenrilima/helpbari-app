import '../domain/entities/routine_occurrence.dart';
import '../../../core/services/notifications/notifications.dart';
import '../../settings/domain/entities/entities.dart';
export 'notification_platform.dart';

enum RoutineNotificationAction { taken, skipped, remindLater }

final class RoutineNotificationProjection {
  const RoutineNotificationProjection({
    required this.occurrenceId,
    required this.scheduleAtUtc,
    required this.userId,
    required this.actions,
    this.category = NotificationCategory.treatment,
    this.itemId = '',
    this.timeId = '',
    this.source = NotificationSource.smartRoutineOccurrence,
  });

  factory RoutineNotificationProjection.fromOccurrence({
    required RoutineOccurrence occurrence,
    required String userId,
  }) => RoutineNotificationProjection(
    occurrenceId: occurrence.id,
    scheduleAtUtc: occurrence.currentScheduledFor,
    userId: userId,
    actions: const {
      RoutineNotificationAction.taken,
      RoutineNotificationAction.skipped,
      RoutineNotificationAction.remindLater,
    },
    category: NotificationCategory.treatment,
    itemId: occurrence.routineId.value,
    timeId:
        '${occurrence.scheduleId?.value ?? occurrence.id}:'
        '${occurrence.originalLocalTime.hour.toString().padLeft(2, '0')}:'
        '${occurrence.originalLocalTime.minute.toString().padLeft(2, '0')}',
    source: NotificationSource.smartRoutineOccurrence,
  );

  final String occurrenceId;
  final DateTime scheduleAtUtc;
  final String userId;
  final Set<RoutineNotificationAction> actions;
  final NotificationCategory category;
  final String itemId;
  final String timeId;
  final NotificationSource source;

  Map<String, String> technicalPayload() => {
    'source': 'smartRoutineOccurrence',
    'occurrenceId': occurrenceId,
    'userId': userId,
  };
}

abstract interface class RoutineNotificationProjectionSink {
  Future<void> replaceWindow(List<RoutineNotificationProjection> projections);
}

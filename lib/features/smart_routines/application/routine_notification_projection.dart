import '../domain/entities/routine_occurrence.dart';
export 'notification_platform.dart';

enum RoutineNotificationAction { taken, skipped, remindLater }

final class RoutineNotificationProjection {
  const RoutineNotificationProjection({
    required this.occurrenceId,
    required this.scheduleAtUtc,
    required this.userId,
    required this.actions,
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
  );

  final String occurrenceId;
  final DateTime scheduleAtUtc;
  final String userId;
  final Set<RoutineNotificationAction> actions;

  Map<String, String> technicalPayload() => {
    'source': 'smartRoutineOccurrence',
    'occurrenceId': occurrenceId,
    'userId': userId,
  };
}

abstract interface class RoutineNotificationProjectionSink {
  Future<void> replaceWindow(List<RoutineNotificationProjection> projections);
}

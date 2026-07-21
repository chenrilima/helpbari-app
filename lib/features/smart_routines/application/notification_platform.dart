import '../../../core/services/notifications/notifications.dart';
import 'routine_notification_projection.dart';

enum NotificationManifestState { scheduled, failed, canceled }

enum NotificationInboxState { pending, processed, failed, rejected }

enum RoutineNotificationActionType { open, taken, skipped, remindLater }

class NotificationManifestEntry {
  const NotificationManifestEntry({
    required this.key,
    required this.userId,
    required this.occurrenceId,
    required this.pluginId,
    required this.projectionVersion,
    required this.scheduledAtUtc,
    required this.payload,
    required this.state,
    required this.updatedAt,
    this.retryCount = 0,
    this.retryAfterUtc,
  });
  final String key;
  final String userId;
  final String occurrenceId;
  final int pluginId;
  final String projectionVersion;
  final DateTime scheduledAtUtc;
  final LocalNotificationPayload payload;
  final NotificationManifestState state;
  final int retryCount;
  final DateTime? retryAfterUtc;
  final DateTime updatedAt;
}

class NotificationActionEnvelope {
  const NotificationActionEnvelope({
    required this.actionId,
    required this.userId,
    required this.occurrenceId,
    required this.action,
    required this.occurredAtUtc,
    required this.receivedAtUtc,
  });
  final String actionId;
  final String userId;
  final String occurrenceId;
  final RoutineNotificationActionType action;
  final DateTime occurredAtUtc;
  final DateTime receivedAtUtc;
}

abstract interface class NotificationManifestRepository {
  Future<List<NotificationManifestEntry>> entries(String userId);
  Future<void> save(NotificationManifestEntry entry);
  Future<void> remove(String userId, String key);
  Future<void> clear(String userId);
}

abstract interface class NotificationActionInbox {
  Future<bool> receive(NotificationActionEnvelope envelope);
  Future<List<NotificationActionEnvelope>> pending(String userId);
  Future<void> complete(String userId, String actionId);
  Future<void> fail(String userId, String actionId, String code);
}

abstract interface class RoutineAdherenceCommandPort {
  Future<void> markOccurrence({
    required String userId,
    required String occurrenceId,
    required String actionId,
    required RoutineNotificationActionType action,
    required DateTime occurredAtUtc,
  });
}

class NotificationProjectionReconciler {
  const NotificationProjectionReconciler({
    required this.manifest,
    required this.scheduler,
  });
  final NotificationManifestRepository manifest;
  final NotificationScheduler scheduler;
  static const projectionVersion = 'routine-v2.1';

  Future<void> reconcile({
    required String userId,
    required Iterable<RoutineNotificationProjection> desired,
    required DateTime now,
  }) async {
    final current = {
      for (final entry in await manifest.entries(userId)) entry.key: entry,
    };
    final wanted = <String, RoutineNotificationProjection>{};
    for (final projection in desired) {
      if (projection.userId != userId ||
          !projection.scheduleAtUtc.isAfter(now)) {
        continue;
      }
      wanted[_key(projection)] = projection;
    }
    for (final entry in current.values.where(
      (entry) => !wanted.containsKey(entry.key),
    )) {
      await scheduler.cancel(entry.payload);
      await manifest.remove(userId, entry.key);
    }
    for (final item in wanted.entries) {
      final projection = item.value;
      final existing = current[item.key];
      if (existing != null &&
          existing.scheduledAtUtc == projection.scheduleAtUtc &&
          existing.projectionVersion == projectionVersion &&
          existing.state == NotificationManifestState.scheduled) {
        continue;
      }
      final payload = LocalNotificationPayload(
        source: NotificationSource.smartRoutineOccurrence,
        entityId: projection.occurrenceId,
        userId: userId,
      );
      try {
        await scheduler.schedule(
          LocalNotificationSchedule(
            key: item.key,
            title: 'Lembrete do HelpBari',
            body: 'Você tem um item da sua rotina para acompanhar.',
            scheduledAt: projection.scheduleAtUtc,
            payload: payload,
          ),
        );
        await manifest.save(
          NotificationManifestEntry(
            key: item.key,
            userId: userId,
            occurrenceId: projection.occurrenceId,
            pluginId: stableNotificationId(item.key),
            projectionVersion: projectionVersion,
            scheduledAtUtc: projection.scheduleAtUtc,
            payload: payload,
            state: NotificationManifestState.scheduled,
            updatedAt: now,
          ),
        );
      } catch (_) {
        final retries = (existing?.retryCount ?? 0) + 1;
        await manifest.save(
          NotificationManifestEntry(
            key: item.key,
            userId: userId,
            occurrenceId: projection.occurrenceId,
            pluginId: stableNotificationId(item.key),
            projectionVersion: projectionVersion,
            scheduledAtUtc: projection.scheduleAtUtc,
            payload: payload,
            state: NotificationManifestState.failed,
            retryCount: retries,
            retryAfterUtc: now.add(Duration(minutes: 1 << retries.clamp(0, 6))),
            updatedAt: now,
          ),
        );
      }
    }
  }

  String _key(RoutineNotificationProjection value) =>
      '${value.userId}:routineOccurrence:${value.occurrenceId}:primary:$projectionVersion';
}

class NotificationActionHandler {
  const NotificationActionHandler({
    required this.inbox,
    required this.commands,
    required this.scheduler,
  });
  final NotificationActionInbox inbox;
  final RoutineAdherenceCommandPort commands;
  final NotificationScheduler scheduler;

  Future<void> process(String userId) async {
    for (final envelope in await inbox.pending(userId)) {
      try {
        if (envelope.action == RoutineNotificationActionType.remindLater) {
          final payload = LocalNotificationPayload(
            source: NotificationSource.smartRoutineOccurrence,
            entityId: envelope.occurrenceId,
            userId: userId,
          );
          await scheduler.schedule(
            LocalNotificationSchedule(
              key:
                  '$userId:routineOccurrence:${envelope.occurrenceId}:snooze:${envelope.actionId}',
              title: 'Lembrete do HelpBari',
              body: 'Você pediu para ser lembrado novamente.',
              scheduledAt: envelope.receivedAtUtc.add(
                const Duration(minutes: 10),
              ),
              payload: payload,
            ),
          );
        } else if (envelope.action != RoutineNotificationActionType.open) {
          await commands.markOccurrence(
            userId: userId,
            occurrenceId: envelope.occurrenceId,
            actionId: envelope.actionId,
            action: envelope.action,
            occurredAtUtc: envelope.occurredAtUtc,
          );
        }
        await inbox.complete(userId, envelope.actionId);
      } catch (_) {
        await inbox.fail(userId, envelope.actionId, 'action_processing_failed');
      }
    }
  }
}

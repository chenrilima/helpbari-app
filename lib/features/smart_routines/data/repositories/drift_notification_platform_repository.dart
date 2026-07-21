import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/notifications/notifications.dart';
import '../../application/notification_platform.dart';

class DriftNotificationPlatformRepository
    implements
        NotificationManifestRepository,
        NotificationActionInbox,
        RoutineAdherenceCommandPort {
  const DriftNotificationPlatformRepository(this.database);
  final AppDatabase database;

  @override
  Future<List<NotificationManifestEntry>> entries(String userId) async =>
      (await (database.select(
            database.notificationManifestRecords,
          )..where((row) => row.userId.equals(userId))).get())
          .map(
            (row) => NotificationManifestEntry(
              key: row.key,
              userId: row.userId,
              occurrenceId: row.occurrenceId,
              pluginId: row.pluginId,
              projectionVersion: row.projectionVersion,
              scheduledAtUtc: row.scheduledAtUtc,
              payload: LocalNotificationPayload.decode(row.payloadJson)!,
              state: NotificationManifestState.values.byName(row.state),
              retryCount: row.retryCount,
              retryAfterUtc: row.retryAfterUtc,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(growable: false);

  @override
  Future<void> save(NotificationManifestEntry entry) => database
      .into(database.notificationManifestRecords)
      .insertOnConflictUpdate(
        NotificationManifestRecordsCompanion.insert(
          key: entry.key,
          userId: entry.userId,
          occurrenceId: entry.occurrenceId,
          pluginId: entry.pluginId,
          projectionVersion: entry.projectionVersion,
          scheduledAtUtc: entry.scheduledAtUtc,
          payloadJson: entry.payload.encode(),
          state: entry.state.name,
          retryCount: Value(entry.retryCount),
          retryAfterUtc: Value(entry.retryAfterUtc),
          updatedAt: entry.updatedAt,
        ),
      );

  @override
  Future<void> remove(String userId, String key) => (database.delete(
    database.notificationManifestRecords,
  )..where((row) => row.userId.equals(userId) & row.key.equals(key))).go();

  @override
  Future<void> clear(String userId) => (database.delete(
    database.notificationManifestRecords,
  )..where((row) => row.userId.equals(userId))).go();

  @override
  Future<bool> receive(NotificationActionEnvelope envelope) async {
    final inserted = await database
        .into(database.notificationActionInboxRecords)
        .insert(
          NotificationActionInboxRecordsCompanion.insert(
            actionId: envelope.actionId,
            userId: envelope.userId,
            occurrenceId: envelope.occurrenceId,
            action: envelope.action.name,
            occurredAtUtc: envelope.occurredAtUtc,
            receivedAtUtc: envelope.receivedAtUtc,
            state: NotificationInboxState.pending.name,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return inserted > 0;
  }

  @override
  Future<List<NotificationActionEnvelope>> pending(String userId) async =>
      (await (database.select(database.notificationActionInboxRecords)
                ..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.state.equals(NotificationInboxState.pending.name),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.receivedAtUtc)]))
              .get())
          .map(
            (row) => NotificationActionEnvelope(
              actionId: row.actionId,
              userId: row.userId,
              occurrenceId: row.occurrenceId,
              action: RoutineNotificationActionType.values.byName(row.action),
              occurredAtUtc: row.occurredAtUtc,
              receivedAtUtc: row.receivedAtUtc,
            ),
          )
          .toList(growable: false);

  @override
  Future<void> complete(String userId, String actionId) =>
      _updateInbox(userId, actionId, NotificationInboxState.processed);

  @override
  Future<void> fail(String userId, String actionId, String code) =>
      _updateInbox(
        userId,
        actionId,
        NotificationInboxState.failed,
        errorCode: code,
      );

  Future<void> _updateInbox(
    String userId,
    String actionId,
    NotificationInboxState state, {
    String? errorCode,
  }) =>
      (database.update(database.notificationActionInboxRecords)..where(
            (row) => row.userId.equals(userId) & row.actionId.equals(actionId),
          ))
          .write(
            NotificationActionInboxRecordsCompanion(
              state: Value(state.name),
              errorCode: Value(errorCode),
              processedAtUtc: Value(DateTime.now().toUtc()),
            ),
          );

  @override
  Future<void> markOccurrence({
    required String userId,
    required String occurrenceId,
    required String actionId,
    required RoutineNotificationActionType action,
    required DateTime occurredAtUtc,
  }) async {
    if (action != RoutineNotificationActionType.taken &&
        action != RoutineNotificationActionType.skipped) {
      throw StateError('Action does not create adherence.');
    }
    final occurrence =
        await (database.select(database.routineOccurrenceRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(occurrenceId),
            ))
            .getSingleOrNull();
    if (occurrence == null) throw StateError('Occurrence not found.');
    final eventId = const Uuid().v5(
      'a5ae6e59-1007-5162-8a93-d938467625ac',
      'notification-action|$userId|$actionId',
    );
    await database
        .into(database.routineAdherenceEventRecords)
        .insert(
          RoutineAdherenceEventRecordsCompanion.insert(
            id: eventId,
            userId: userId,
            occurrenceId: occurrenceId,
            routineId: occurrence.routineId,
            planId: occurrence.planId,
            scheduleId: Value(occurrence.scheduleId),
            type: action.name,
            actor: 'user',
            occurredAtUtc: occurredAtUtc.toUtc(),
            recordedAtUtc: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            syncStatus: 'pendingCreate',
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

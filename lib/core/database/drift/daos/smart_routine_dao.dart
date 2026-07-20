import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/smart_routine_records.dart';

part 'smart_routine_dao.g.dart';

@DriftAccessor(
  tables: [
    SmartRoutineRecords,
    RoutinePlanRecords,
    RoutineScheduleRecords,
    RoutinePauseRecords,
    RoutineOccurrenceRecords,
    RoutineAdherenceEventRecords,
  ],
)
class SmartRoutineDao extends DatabaseAccessor<AppDatabase>
    with _$SmartRoutineDaoMixin {
  SmartRoutineDao(super.db);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<void> upsertRoutine(SmartRoutineRecordsCompanion row) =>
      into(smartRoutineRecords).insertOnConflictUpdate(row);
  Future<void> upsertPlan(RoutinePlanRecordsCompanion row) =>
      into(routinePlanRecords).insertOnConflictUpdate(row);
  Future<void> upsertSchedule(RoutineScheduleRecordsCompanion row) =>
      into(routineScheduleRecords).insertOnConflictUpdate(row);
  Future<void> upsertPause(RoutinePauseRecordsCompanion row) =>
      into(routinePauseRecords).insertOnConflictUpdate(row);

  Future<SmartRoutineRecord?> getRoutine(String userId, String id) =>
      (select(smartRoutineRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<List<SmartRoutineRecord>> getRoutines(String userId) => (select(
    smartRoutineRecords,
  )..where((row) => row.userId.equals(userId))).get();
  Future<List<RoutinePlanRecord>> getPlans(String userId, String routineId) =>
      (select(routinePlanRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) & row.routineId.equals(routineId),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.revision)]))
          .get();
  Future<RoutinePlanRecord?> getPlan(String userId, String id) =>
      (select(routinePlanRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<RoutineScheduleRecord?> getSchedule(String userId, String id) =>
      (select(routineScheduleRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<RoutinePauseRecord?> getPause(String userId, String id) =>
      (select(routinePauseRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<List<RoutineScheduleRecord>> getSchedules(
    String userId,
    String planId,
  ) =>
      (select(routineScheduleRecords)
            ..where(
              (row) => row.userId.equals(userId) & row.planId.equals(planId),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.displayOrder)]))
          .get();
  Future<List<RoutinePauseRecord>> getPauses(String userId, String routineId) =>
      (select(routinePauseRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.routineId.equals(routineId),
          ))
          .get();

  Future<RoutineOccurrenceRecord?> getOccurrence(String userId, String id) =>
      (select(routineOccurrenceRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<List<RoutineOccurrenceRecord>> getOccurrencesByInterval(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) =>
      (select(routineOccurrenceRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.originalScheduledFor.isBiggerOrEqualValue(
                    startInclusive,
                  ) &
                  row.originalScheduledFor.isSmallerThanValue(endExclusive),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.originalScheduledFor)]))
          .get();

  Future<bool> insertOccurrenceIdempotent(
    RoutineOccurrenceRecordsCompanion row,
  ) async {
    final inserted = await into(
      routineOccurrenceRecords,
    ).insert(row, mode: InsertMode.insertOrIgnore);
    if (inserted != 0) return true;
    final current = await getOccurrence(row.userId.value, row.id.value);
    if (current == null || !_sameOccurrence(current, row)) {
      throw StateError('routine_occurrence_payload_conflict');
    }
    return false;
  }

  Future<RoutineAdherenceEventRecord?> getEvent(String userId, String id) =>
      (select(routineAdherenceEventRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<void> updateOccurrenceCurrentWindow(
    RoutineOccurrenceRecordsCompanion row,
  ) =>
      (update(routineOccurrenceRecords)..where(
            (current) =>
                current.userId.equals(row.userId.value) &
                current.id.equals(row.id.value),
          ))
          .write(
            RoutineOccurrenceRecordsCompanion(
              status: row.status,
              scheduledFor: row.scheduledFor,
              windowStartsAt: row.windowStartsAt,
              onTimeEndsAt: row.onTimeEndsAt,
              windowEndsAt: row.windowEndsAt,
              updatedAt: row.updatedAt,
              syncStatus: row.syncStatus,
            ),
          );
  Future<List<RoutineAdherenceEventRecord>> getEventsByOccurrence(
    String userId,
    String occurrenceId,
  ) =>
      (select(routineAdherenceEventRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.occurrenceId.equals(occurrenceId),
            )
            ..orderBy([
              (row) => OrderingTerm.asc(row.recordedAtUtc),
              (row) => OrderingTerm.asc(row.id),
            ]))
          .get();

  Future<bool> insertEventIdempotent(
    RoutineAdherenceEventRecordsCompanion row,
  ) async {
    final parent = await getOccurrence(
      row.userId.value,
      row.occurrenceId.value,
    );
    if (parent == null) throw StateError('routine_occurrence_parent_missing');
    final inserted = await into(
      routineAdherenceEventRecords,
    ).insert(row, mode: InsertMode.insertOrIgnore);
    if (inserted != 0) return true;
    final current = await getEvent(row.userId.value, row.id.value);
    if (current == null || !_sameEvent(current, row)) {
      throw StateError('routine_adherence_event_payload_conflict');
    }
    return false;
  }

  Future<List<RoutineOccurrenceRecord>> getPendingOccurrences(String userId) =>
      (select(routineOccurrenceRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();

  Future<List<SmartRoutineRecord>> getPendingRoutines(String userId) =>
      (select(smartRoutineRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();
  Future<List<RoutinePlanRecord>> getPendingPlans(String userId) =>
      (select(routinePlanRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();
  Future<List<RoutineScheduleRecord>> getPendingSchedules(String userId) =>
      (select(routineScheduleRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();
  Future<List<RoutinePauseRecord>> getPendingPauses(String userId) =>
      (select(routinePauseRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();
  Future<List<RoutineAdherenceEventRecord>> getPendingEvents(String userId) =>
      (select(routineAdherenceEventRecords)..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          ))
          .get();

  Future<void> updateOccurrenceSyncMetadata({
    required String userId,
    required String id,
    required String status,
    String? previousStatus,
    int? attempts,
    String? error,
  }) =>
      (update(
        routineOccurrenceRecords,
      )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
        RoutineOccurrenceRecordsCompanion(
          syncStatus: Value(status),
          previousSyncStatus: Value(previousStatus),
          syncAttempts: attempts == null
              ? const Value.absent()
              : Value(attempts),
          lastSyncError: Value(error),
        ),
      );
  Future<void> updateEventSyncMetadata({
    required String userId,
    required String id,
    required String status,
    String? previousStatus,
    int? attempts,
    String? error,
  }) =>
      (update(
        routineAdherenceEventRecords,
      )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
        RoutineAdherenceEventRecordsCompanion(
          syncStatus: Value(status),
          previousSyncStatus: Value(previousStatus),
          syncAttempts: attempts == null
              ? const Value.absent()
              : Value(attempts),
          lastSyncError: Value(error),
        ),
      );

  Future<void> updateSyncStatus({
    required String table,
    required String userId,
    required String id,
    required String status,
    String? error,
  }) {
    const allowed = {
      'smart_routine_records',
      'routine_plan_records',
      'routine_schedule_records',
      'routine_pause_records',
      'routine_occurrence_records',
      'routine_adherence_event_records',
    };
    if (!allowed.contains(table)) throw ArgumentError.value(table, 'table');
    return customStatement(
      'UPDATE $table SET sync_status = ?, last_sync_error = ? WHERE user_id = ? AND id = ?',
      [status, error, userId, id],
    );
  }

  Future<DateTime?> getSyncCursor(String userId, String key) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (row) =>
                    row.userId.equals(userId) & row.repositoryKey.equals(key),
              ))
              .getSingleOrNull())
          ?.lastPullAt;

  Future<void> saveSyncCursor(String userId, String key, DateTime value) =>
      attachedDatabase
          .into(attachedDatabase.syncCursors)
          .insertOnConflictUpdate(
            SyncCursorsCompanion.insert(
              userId: userId,
              repositoryKey: key,
              lastPullAt: Value(value),
              lastSyncAt: Value(value),
              status: const Value('success'),
            ),
          );

  bool _sameOccurrence(
    RoutineOccurrenceRecord current,
    RoutineOccurrenceRecordsCompanion row,
  ) =>
      current.routineId == row.routineId.value &&
      current.planId == row.planId.value &&
      current.scheduleId == row.scheduleId.value &&
      current.origin == row.origin.value &&
      current.status == row.status.value &&
      current.originalClinicalDate == row.originalClinicalDate.value &&
      current.originalLocalHour == row.originalLocalHour.value &&
      current.originalLocalMinute == row.originalLocalMinute.value &&
      current.originalTimeZone == row.originalTimeZone.value &&
      current.expectationKind == row.expectationKind.value &&
      current.sequence == row.sequence.value &&
      current.originalScheduledFor == row.originalScheduledFor.value &&
      current.originalWindowStartsAt == row.originalWindowStartsAt.value &&
      current.originalOnTimeEndsAt == row.originalOnTimeEndsAt.value &&
      current.originalWindowEndsAt == row.originalWindowEndsAt.value &&
      current.scheduledFor == row.scheduledFor.value &&
      current.windowStartsAt == row.windowStartsAt.value &&
      current.onTimeEndsAt == row.onTimeEndsAt.value &&
      current.windowEndsAt == row.windowEndsAt.value;

  bool _sameEvent(
    RoutineAdherenceEventRecord current,
    RoutineAdherenceEventRecordsCompanion row,
  ) =>
      current.occurrenceId == row.occurrenceId.value &&
      current.routineId == row.routineId.value &&
      current.planId == row.planId.value &&
      current.scheduleId == row.scheduleId.value &&
      current.type == row.type.value &&
      current.actor == row.actor.value &&
      current.occurredAtUtc == row.occurredAtUtc.value &&
      current.recordedAtUtc == row.recordedAtUtc.value &&
      current.referencedEventId == row.referencedEventId.value &&
      current.correctionAction == row.correctionAction.value &&
      current.replacementType == row.replacementType.value &&
      current.replacementOccurredAtUtc == row.replacementOccurredAtUtc.value &&
      current.rescheduledForUtc == row.rescheduledForUtc.value &&
      current.rescheduledWindowStartsAtUtc ==
          row.rescheduledWindowStartsAtUtc.value &&
      current.rescheduledOnTimeEndsAtUtc ==
          row.rescheduledOnTimeEndsAtUtc.value &&
      current.rescheduledWindowEndsAtUtc ==
          row.rescheduledWindowEndsAtUtc.value &&
      current.note == row.note.value &&
      current.actualDoseValue == row.actualDoseValue.value &&
      current.actualDoseUnit == row.actualDoseUnit.value &&
      current.actualDoseOriginalText == row.actualDoseOriginalText.value;
}

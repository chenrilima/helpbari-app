import 'package:drift/drift.dart';

mixin SmartRoutineSyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  TextColumn get previousSyncStatus => text().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}

@TableIndex(name: 'smart_routines_user_status_idx', columns: {#userId, #status})
@TableIndex(
  name: 'smart_routines_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class SmartRoutineRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get category => text()();
  TextColumn get displayName => text()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  TextColumn get prescriptionId => text().nullable()();
  TextColumn get prescriptionItemId => text().nullable()();
  TextColumn get personalNotes => text().nullable()();
  TextColumn get iconKey => text().nullable()();
}

@TableIndex(
  name: 'routine_plans_user_routine_revision_idx',
  columns: {#userId, #routineId, #revision},
)
@TableIndex(
  name: 'routine_plans_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class RoutinePlanRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get routineId => text()();
  IntColumn get revision => integer()();
  TextColumn get mode => text()();
  TextColumn get durationType => text()();
  TextColumn get effectiveFrom => text()();
  TextColumn get effectiveUntil => text().nullable()();
  TextColumn get doseValue => text().nullable()();
  TextColumn get doseUnit => text().nullable()();
  TextColumn get doseOriginalText => text().nullable()();
  TextColumn get route => text().nullable()();
  TextColumn get clinicalInstructions => text().nullable()();
  DateTimeColumn get activatedAt => dateTime().nullable()();
  DateTimeColumn get replacedAt => dateTime().nullable()();
  TextColumn get previousPlanId => text().nullable()();
}

@TableIndex(
  name: 'routine_schedules_user_plan_idx',
  columns: {#userId, #planId, #displayOrder},
)
@TableIndex(
  name: 'routine_schedules_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class RoutineScheduleRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get routineId => text()();
  TextColumn get planId => text()();
  TextColumn get ruleJson => text()();
  TextColumn get timeZone => text()();
  TextColumn get reminderPreference => text()();
  IntColumn get earlyToleranceSeconds => integer()();
  IntColumn get onTimeToleranceSeconds => integer()();
  IntColumn get lateToleranceSeconds => integer()();
  BoolColumn get isEnabled => boolean()();
  IntColumn get displayOrder => integer()();
}

@TableIndex(
  name: 'routine_pauses_user_routine_interval_idx',
  columns: {#userId, #routineId, #startsAt, #endsAt},
)
@TableIndex(
  name: 'routine_pauses_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class RoutinePauseRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get routineId => text()();
  TextColumn get planId => text().nullable()();
  TextColumn get scope => text()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  TextColumn get reason => text().nullable()();
}

@TableIndex(
  name: 'routine_occurrences_user_routine_original_idx',
  columns: {#userId, #routineId, #originalScheduledFor},
)
@TableIndex(
  name: 'routine_occurrences_user_schedule_date_idx',
  columns: {#userId, #scheduleId, #originalClinicalDate},
)
@TableIndex(
  name: 'routine_occurrences_user_window_idx',
  columns: {#userId, #windowEndsAt},
)
@TableIndex(
  name: 'routine_occurrences_user_sync_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class RoutineOccurrenceRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get routineId => text()();
  TextColumn get planId => text()();
  TextColumn get scheduleId => text().nullable()();
  TextColumn get origin => text()();
  TextColumn get status => text()();
  TextColumn get originalClinicalDate => text()();
  IntColumn get originalLocalHour => integer()();
  IntColumn get originalLocalMinute => integer()();
  TextColumn get originalTimeZone => text()();
  TextColumn get expectationKind => text()();
  IntColumn get sequence => integer()();
  DateTimeColumn get originalScheduledFor => dateTime()();
  DateTimeColumn get originalWindowStartsAt => dateTime()();
  DateTimeColumn get originalOnTimeEndsAt => dateTime()();
  DateTimeColumn get originalWindowEndsAt => dateTime()();
  DateTimeColumn get scheduledFor => dateTime()();
  DateTimeColumn get windowStartsAt => dateTime()();
  DateTimeColumn get onTimeEndsAt => dateTime()();
  DateTimeColumn get windowEndsAt => dateTime()();
}

@TableIndex(
  name: 'routine_events_user_occurrence_idx',
  columns: {#userId, #occurrenceId, #recordedAtUtc},
)
@TableIndex(
  name: 'routine_events_user_recorded_idx',
  columns: {#userId, #recordedAtUtc, #id},
)
@TableIndex(
  name: 'routine_events_user_reference_idx',
  columns: {#userId, #referencedEventId},
)
@TableIndex(
  name: 'routine_events_user_sync_idx',
  columns: {#userId, #syncStatus, #createdAt},
)
class RoutineAdherenceEventRecords extends Table with SmartRoutineSyncColumns {
  TextColumn get occurrenceId => text()();
  TextColumn get routineId => text()();
  TextColumn get planId => text()();
  TextColumn get scheduleId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get actor => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get recordedAtUtc => dateTime()();
  TextColumn get referencedEventId => text().nullable()();
  TextColumn get correctionAction => text().nullable()();
  TextColumn get replacementType => text().nullable()();
  DateTimeColumn get replacementOccurredAtUtc => dateTime().nullable()();
  DateTimeColumn get rescheduledForUtc => dateTime().nullable()();
  DateTimeColumn get rescheduledWindowStartsAtUtc => dateTime().nullable()();
  DateTimeColumn get rescheduledOnTimeEndsAtUtc => dateTime().nullable()();
  DateTimeColumn get rescheduledWindowEndsAtUtc => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get actualDoseValue => text().nullable()();
  TextColumn get actualDoseUnit => text().nullable()();
  TextColumn get actualDoseOriginalText => text().nullable()();
}

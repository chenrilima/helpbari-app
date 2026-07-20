import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../../core/database/drift/app_database.dart';
import '../../../core/services/clock_service.dart';
import 'unified_treatment_cutover_service.dart';
import 'unified_treatment_migrator.dart';
import 'unified_treatment_rollout.dart';

enum TreatmentSpecialization { medication, vitamin }

enum TreatmentDailyState { pending, taken, skipped }

final class TreatmentProjection {
  const TreatmentProjection({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.dosage,
    this.notes,
  });
  final String id;
  final String name;
  final int hour;
  final int minute;
  final String? dosage;
  final String? notes;
}

final class TreatmentLogProjection {
  const TreatmentLogProjection({
    required this.id,
    required this.treatmentId,
    required this.date,
    required this.state,
  });
  final String id;
  final String treatmentId;
  final DateTime date;
  final TreatmentDailyState state;
}

/// Compatibility boundary for Medication/Vitamin presentation. All clinical
/// writes are Smart Routines aggregate writes; legacy tables are never used.
final class UnifiedTreatmentStore {
  const UnifiedTreatmentStore({
    required this.database,
    required this.clock,
    required this.userId,
  });

  final AppDatabase database;
  final ClockService clock;
  final String userId;
  static const Uuid _uuid = Uuid();
  static const _namespace = 'a5ae6e59-1007-5162-8a93-d938467625ac';

  Future<List<TreatmentProjection>> list(TreatmentSpecialization kind) async {
    await _prepare(requireWrite: false);
    final routines =
        await (database.select(database.smartRoutineRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.deletedAt.isNull() &
                  row.status.isNotValue('archived'),
            ))
            .get();
    if (routines.isEmpty) return const [];
    final plans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.isIn(routines.map((value) => value.id)) &
                    row.category.equals(kind.name) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    final latestPlanByRoutine = <String, RoutinePlanRecord>{};
    for (final plan in plans) {
      latestPlanByRoutine.putIfAbsent(plan.routineId, () => plan);
    }
    final planIds = latestPlanByRoutine.values
        .map((value) => value.id)
        .toList();
    if (planIds.isEmpty) return const [];
    final schedules =
        await (database.select(database.routineScheduleRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.planId.isIn(planIds) &
                    row.isEnabled.equals(true) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.displayOrder)]))
            .get();
    final firstScheduleByPlan = <String, RoutineScheduleRecord>{};
    for (final schedule in schedules) {
      firstScheduleByPlan.putIfAbsent(schedule.planId, () => schedule);
    }
    final result = <TreatmentProjection>[];
    for (final routine in routines) {
      final plan = latestPlanByRoutine[routine.id];
      if (plan == null) continue;
      final schedule = firstScheduleByPlan[plan.id];
      if (schedule == null) continue;
      final time = _firstDailyTime(schedule.ruleJson);
      if (time == null) continue;
      result.add(
        TreatmentProjection(
          id: routine.id,
          name: routine.displayName,
          hour: time.$1,
          minute: time.$2,
          dosage: plan.doseOriginalText ?? _dose(plan),
          notes: routine.personalNotes,
        ),
      );
    }
    result.sort((a, b) {
      final time = (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
      return time != 0 ? time : a.name.compareTo(b.name);
    });
    return result;
  }

  Future<void> save({
    required TreatmentSpecialization kind,
    required TreatmentProjection value,
  }) async {
    await _prepare(requireWrite: true);
    final existing =
        await (database.select(database.smartRoutineRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(value.id),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _create(kind, value);
    } else {
      await _revise(kind, existing, value);
    }
    await _markNewClinicalWrite(value.id);
  }

  Future<void> archive(String id) async {
    await _prepare(requireWrite: true);
    final now = clock.now().toUtc();
    await (database.update(
      database.smartRoutineRecords,
    )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
      SmartRoutineRecordsCompanion(
        status: const Value('archived'),
        updatedAt: Value(now),
        syncStatus: const Value('pendingUpdate'),
      ),
    );
    await _markNewClinicalWrite(id);
  }

  Future<List<TreatmentLogProjection>> logs(
    TreatmentSpecialization kind,
    DateTime start,
    DateTime end,
  ) async {
    await _prepare(requireWrite: false);
    final startDate = _date(start);
    final endDate = _date(end);
    final occurrences =
        await (database.select(database.routineOccurrenceRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.originalClinicalDate.isBiggerOrEqualValue(startDate) &
                  row.originalClinicalDate.isSmallerOrEqualValue(endDate),
            ))
            .get();
    if (occurrences.isEmpty) return const [];
    final plans =
        await (database.select(database.routinePlanRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.id.isIn(occurrences.map((value) => value.planId)) &
                  row.category.equals(kind.name),
            ))
            .get();
    final plansById = {for (final plan in plans) plan.id: plan};
    final relevantOccurrences = occurrences
        .where((occurrence) => plansById.containsKey(occurrence.planId))
        .toList();
    if (relevantOccurrences.isEmpty) return const [];
    final events =
        await (database.select(database.routineAdherenceEventRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.occurrenceId.isIn(
                      relevantOccurrences.map((value) => value.id),
                    ),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.recordedAtUtc),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    final eventsByOccurrence = <String, List<RoutineAdherenceEventRecord>>{};
    for (final event in events) {
      eventsByOccurrence.putIfAbsent(event.occurrenceId, () => []).add(event);
    }
    final result = <TreatmentLogProjection>[];
    for (final occurrence in relevantOccurrences) {
      final state = _project(eventsByOccurrence[occurrence.id] ?? const []);
      result.add(
        TreatmentLogProjection(
          id: occurrence.id,
          treatmentId: occurrence.routineId,
          date: DateTime.parse(occurrence.originalClinicalDate),
          state: state,
        ),
      );
    }
    return result;
  }

  Future<int> pendingCount(
    TreatmentSpecialization kind,
    DateTime evaluatedDate,
  ) async {
    await _prepare(requireWrite: false);
    final treatments = await list(kind);
    final dayLogs = await logs(kind, evaluatedDate, evaluatedDate);
    final resolved = dayLogs
        .where((value) => value.state != TreatmentDailyState.pending)
        .map((value) => value.treatmentId)
        .toSet();
    final treatmentIds = treatments.map((value) => value.id).toList();
    if (treatmentIds.isEmpty) return 0;
    final plans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.isIn(treatmentIds) &
                    row.category.equals(kind.name) &
                    row.replacedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    final planByRoutine = <String, RoutinePlanRecord>{};
    for (final plan in plans) {
      planByRoutine.putIfAbsent(plan.routineId, () => plan);
    }
    final schedules = planByRoutine.isEmpty
        ? const <RoutineScheduleRecord>[]
        : await (database.select(database.routineScheduleRecords)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.planId.isIn(
                      planByRoutine.values.map((value) => value.id),
                    ) &
                    row.isEnabled.equals(true) &
                    row.deletedAt.isNull(),
              ))
              .get();
    final schedulesByPlan = <String, List<RoutineScheduleRecord>>{};
    for (final schedule in schedules) {
      schedulesByPlan.putIfAbsent(schedule.planId, () => []).add(schedule);
    }
    var count = 0;
    for (final treatment in treatments) {
      if (resolved.contains(treatment.id)) continue;
      final plan = planByRoutine[treatment.id];
      if (plan == null || !_effectiveOn(plan, evaluatedDate)) continue;
      if ((schedulesByPlan[plan.id] ?? const []).any(
        (value) => _firstDailyTime(value.ruleJson) != null,
      )) {
        count++;
      }
    }
    return count;
  }

  Future<double?> adherence(
    TreatmentSpecialization kind,
    DateTime start,
    DateTime end,
  ) async {
    final values = await logs(kind, start, end);
    final resolved = values
        .where((value) => value.state != TreatmentDailyState.pending)
        .toList();
    if (resolved.isEmpty) return null;
    return resolved
            .where((value) => value.state == TreatmentDailyState.taken)
            .length /
        resolved.length *
        100;
  }

  Future<TreatmentLogProjection> setDailyState({
    required TreatmentSpecialization kind,
    required String treatmentId,
    required DateTime date,
    required TreatmentDailyState state,
  }) async {
    await _prepare(requireWrite: true);
    final occurrence = await _ensureOccurrence(kind, treatmentId, date);
    final events =
        await (database.select(database.routineAdherenceEventRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.occurrenceId.equals(occurrence.id),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.recordedAtUtc),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    final current = _project(events);
    if (current == state) {
      return TreatmentLogProjection(
        id: occurrence.id,
        treatmentId: treatmentId,
        date: date,
        state: state,
      );
    }
    final now = clock.now().toUtc();
    if (state == TreatmentDailyState.pending) {
      final terminal = events.lastWhere(
        (event) => event.type == 'taken' || event.type == 'skipped',
      );
      final id = _uuid.v5(
        _namespace,
        'correction|${occurrence.id}|${terminal.id}',
      );
      await _appendEvent(
        occurrence,
        id: id,
        type: 'correction',
        occurredAt: now,
        recordedAt: now,
        referencedEventId: terminal.id,
        correctionAction: 'invalidate',
      );
    } else {
      final type = state.name;
      final previousEventId = events.isEmpty ? 'origin' : events.last.id;
      final id = _uuid.v5(
        _namespace,
        'terminal|${occurrence.id}|$type|after:$previousEventId',
      );
      await _appendEvent(
        occurrence,
        id: id,
        type: type,
        occurredAt: now,
        recordedAt: now,
      );
    }
    await _markNewClinicalWrite(treatmentId);
    return TreatmentLogProjection(
      id: occurrence.id,
      treatmentId: treatmentId,
      date: date,
      state: state,
    );
  }

  Future<void> _create(
    TreatmentSpecialization kind,
    TreatmentProjection value,
  ) async {
    final now = clock.now().toUtc();
    final timeZone = await _timeZone();
    final planId = _uuid.v5(_namespace, 'manual|$userId|${value.id}|plan|1');
    final scheduleId = _uuid.v5(
      _namespace,
      'manual|$userId|${value.id}|schedule|1',
    );
    await database.transaction(() async {
      await database
          .into(database.smartRoutineRecords)
          .insert(
            SmartRoutineRecordsCompanion.insert(
              id: value.id,
              userId: userId,
              category: kind.name,
              displayName: value.name,
              status: 'active',
              source: 'manual',
              personalNotes: Value(value.notes),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
          );
      await database
          .into(database.routinePlanRecords)
          .insert(
            RoutinePlanRecordsCompanion.insert(
              id: planId,
              userId: userId,
              routineId: value.id,
              revision: 1,
              category: Value(kind.name),
              mode: 'scheduled',
              durationType: 'unknown',
              effectiveFrom: _date(now),
              doseOriginalText: Value(value.dosage),
              activatedAt: Value(now),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
          );
      await _insertSchedule(
        id: scheduleId,
        routineId: value.id,
        planId: planId,
        hour: value.hour,
        minute: value.minute,
        timeZone: timeZone,
        now: now,
      );
    });
  }

  Future<void> _revise(
    TreatmentSpecialization kind,
    SmartRoutineRecord routine,
    TreatmentProjection value,
  ) async {
    final plans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.equals(routine.id),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    if (plans.isEmpty) throw StateError('routine_plan_missing');
    final current = plans.first;
    final now = clock.now().toUtc();
    final revision = current.revision + 1;
    final planId = _uuid.v5(
      _namespace,
      'manual|$userId|${routine.id}|plan|$revision',
    );
    final scheduleId = _uuid.v5(
      _namespace,
      'manual|$userId|${routine.id}|schedule|$revision',
    );
    final timeZone = await _timeZone();
    await database.transaction(() async {
      await (database.update(database.smartRoutineRecords)..where(
            (row) => row.userId.equals(userId) & row.id.equals(routine.id),
          ))
          .write(
            SmartRoutineRecordsCompanion(
              displayName: Value(value.name),
              category: Value(kind.name),
              personalNotes: Value(value.notes),
              updatedAt: Value(now),
              syncStatus: const Value('pendingUpdate'),
            ),
          );
      await (database.update(database.routinePlanRecords)..where(
            (row) => row.userId.equals(userId) & row.id.equals(current.id),
          ))
          .write(
            RoutinePlanRecordsCompanion(
              replacedAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pendingUpdate'),
            ),
          );
      await database
          .into(database.routinePlanRecords)
          .insert(
            RoutinePlanRecordsCompanion.insert(
              id: planId,
              userId: userId,
              routineId: routine.id,
              revision: revision,
              category: Value(kind.name),
              mode: 'scheduled',
              durationType: 'unknown',
              effectiveFrom: _date(now),
              doseOriginalText: Value(value.dosage),
              activatedAt: Value(now),
              previousPlanId: Value(current.id),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
          );
      await _insertSchedule(
        id: scheduleId,
        routineId: routine.id,
        planId: planId,
        hour: value.hour,
        minute: value.minute,
        timeZone: timeZone,
        now: now,
      );
    });
  }

  Future<void> _insertSchedule({
    required String id,
    required String routineId,
    required String planId,
    required int hour,
    required int minute,
    required String timeZone,
    required DateTime now,
  }) => database
      .into(database.routineScheduleRecords)
      .insert(
        RoutineScheduleRecordsCompanion.insert(
          id: id,
          userId: userId,
          routineId: routineId,
          planId: planId,
          ruleJson: jsonEncode({
            'schemaVersion': 1,
            'type': 'dailyAtTimes',
            'times': [
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            ],
          }),
          timeZone: timeZone,
          reminderPreference: 'enabled',
          earlyToleranceSeconds: 0,
          onTimeToleranceSeconds: 1800,
          lateToleranceSeconds: 43200,
          isEnabled: true,
          displayOrder: 0,
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pendingCreate',
        ),
      );

  Future<RoutineOccurrenceRecord> _ensureOccurrence(
    TreatmentSpecialization kind,
    String treatmentId,
    DateTime date,
  ) async {
    final routine =
        await (database.select(database.smartRoutineRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.id.equals(treatmentId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (routine == null || routine.status != 'active') {
      throw StateError('routine_not_active');
    }
    final plans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.equals(treatmentId) &
                    row.category.equals(kind.name),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    if (plans.isEmpty) throw StateError('routine_plan_missing');
    final plan = plans.firstWhere(
      (value) => value.replacedAt == null && _effectiveOn(value, date),
      orElse: () => throw StateError('routine_plan_not_effective'),
    );
    final schedules =
        await (database.select(database.routineScheduleRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.planId.equals(plan.id) &
                  row.isEnabled.equals(true),
            ))
            .get();
    if (schedules.length != 1) throw StateError('routine_schedule_ambiguous');
    final schedule = schedules.single;
    final time = _firstDailyTime(schedule.ruleJson);
    if (time == null) throw StateError('routine_schedule_not_daily');
    final clinicalDate = _date(date);
    final id = _uuid.v5(
      _namespace,
      'v1|routine:$treatmentId|plan:${plan.id}|schedule:${schedule.id}'
      '|date:$clinicalDate|time:${time.$1}:${time.$2}|tz:${schedule.timeZone}|seq:0',
    );
    final existing =
        await (database.select(database.routineOccurrenceRecords)
              ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
            .getSingleOrNull();
    if (existing != null) return existing;
    final target = tz.TZDateTime(
      tz.getLocation(schedule.timeZone),
      date.year,
      date.month,
      date.day,
      time.$1,
      time.$2,
    ).toUtc();
    final pauses =
        await (database.select(database.routinePauseRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.routineId.equals(treatmentId) &
                  row.deletedAt.isNull() &
                  row.startsAt.isSmallerOrEqualValue(target) &
                  (row.endsAt.isNull() | row.endsAt.isBiggerThanValue(target)),
            ))
            .get();
    if (pauses.any(
      (pause) => pause.planId == null || pause.planId == plan.id,
    )) {
      throw StateError('routine_paused_at_occurrence');
    }
    final now = clock.now().toUtc();
    final companion = RoutineOccurrenceRecordsCompanion.insert(
      id: id,
      userId: userId,
      routineId: treatmentId,
      planId: plan.id,
      scheduleId: Value(schedule.id),
      origin: 'generated',
      status: 'expected',
      originalClinicalDate: clinicalDate,
      originalLocalHour: time.$1,
      originalLocalMinute: time.$2,
      originalTimeZone: schedule.timeZone,
      expectationKind: 'recurringExpectation',
      sequence: 0,
      originalScheduledFor: target,
      originalWindowStartsAt: target,
      originalOnTimeEndsAt: target.add(
        Duration(seconds: schedule.onTimeToleranceSeconds),
      ),
      originalWindowEndsAt: target.add(
        Duration(seconds: schedule.lateToleranceSeconds),
      ),
      scheduledFor: target,
      windowStartsAt: target,
      onTimeEndsAt: target.add(
        Duration(seconds: schedule.onTimeToleranceSeconds),
      ),
      windowEndsAt: target.add(
        Duration(seconds: schedule.lateToleranceSeconds),
      ),
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pendingCreate',
    );
    await database.into(database.routineOccurrenceRecords).insert(companion);
    return (await (database.select(database.routineOccurrenceRecords)
          ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
        .getSingle());
  }

  Future<void> _appendEvent(
    RoutineOccurrenceRecord occurrence, {
    required String id,
    required String type,
    required DateTime occurredAt,
    required DateTime recordedAt,
    String? referencedEventId,
    String? correctionAction,
  }) => database
      .into(database.routineAdherenceEventRecords)
      .insert(
        RoutineAdherenceEventRecordsCompanion.insert(
          id: id,
          userId: userId,
          occurrenceId: occurrence.id,
          routineId: occurrence.routineId,
          planId: occurrence.planId,
          scheduleId: Value(occurrence.scheduleId),
          type: type,
          actor: 'user',
          occurredAtUtc: occurredAt,
          recordedAtUtc: recordedAt,
          referencedEventId: Value(referencedEventId),
          correctionAction: Value(correctionAction),
          createdAt: recordedAt,
          updatedAt: recordedAt,
          syncStatus: 'pendingCreate',
        ),
        mode: InsertMode.insertOrIgnore,
      );

  TreatmentDailyState _project(List<RoutineAdherenceEventRecord> events) {
    final invalidated = events
        .where(
          (event) =>
              event.type == 'correction' &&
              event.correctionAction == 'invalidate' &&
              event.referencedEventId != null,
        )
        .map((event) => event.referencedEventId)
        .toSet();
    for (final event in events.reversed) {
      if (invalidated.contains(event.id)) continue;
      if (event.type == 'taken') return TreatmentDailyState.taken;
      if (event.type == 'skipped') return TreatmentDailyState.skipped;
    }
    return TreatmentDailyState.pending;
  }

  (int, int)? _firstDailyTime(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (json['type'] != 'dailyAtTimes') return null;
    final times = json['times'] as List<dynamic>;
    if (times.isEmpty) return null;
    final parts = (times.first as String).split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  String? _dose(RoutinePlanRecord plan) {
    if (plan.doseValue == null) return null;
    return [plan.doseValue, plan.doseUnit].whereType<String>().join(' ').trim();
  }

  bool _effectiveOn(RoutinePlanRecord plan, DateTime date) {
    final value = _date(date);
    return value.compareTo(plan.effectiveFrom) >= 0 &&
        (plan.effectiveUntil == null ||
            value.compareTo(plan.effectiveUntil!) <= 0);
  }

  Future<String> _timeZone() async {
    final records =
        await (database.select(database.privacyConsentRecords)
              ..where((row) => row.userId.equals(userId))
              ..orderBy([(row) => OrderingTerm.desc(row.acceptedAt)]))
            .get();
    for (final record in records) {
      try {
        tz.getLocation(record.timezone);
        return record.timezone;
      } on Object {
        continue;
      }
    }
    throw StateError('routine_timezone_validation_required');
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<void> _prepare({required bool requireWrite}) async {
    final now = clock.now().toUtc();
    final rollout = UnifiedTreatmentRolloutRepository(database);
    final cutover = UnifiedTreatmentCutoverService(
      database: database,
      rollout: rollout,
    );
    if (await rollout.isEnabled(UnifiedTreatmentFlag.migrationEnabled, now)) {
      final canMigrate = await cutover.prepareMigration(
        userId: userId,
        evaluatedAtUtc: now,
      );
      if (!canMigrate) {
        throw StateError('unified_treatment_migration_transition_blocked');
      }
      await UnifiedTreatmentMigrator(
        database: database,
      ).migrate(userId: userId, startedAtUtc: now);
    }
    await cutover.attempt(userId: userId, evaluatedAtUtc: now);
    if (requireWrite) {
      await cutover.enableNewWrites(userId: userId, evaluatedAtUtc: now);
    }
    final state = await rollout.stateFor(userId);
    if (requireWrite && state != UnifiedTreatmentCutoverPhase.writeNew) {
      throw StateError('unified_treatment_write_disabled');
    }
    if (!requireWrite &&
        state != UnifiedTreatmentCutoverPhase.readNew &&
        state != UnifiedTreatmentCutoverPhase.writeNew) {
      throw StateError('unified_treatment_read_disabled');
    }
  }

  Future<void> _markNewClinicalWrite(String routineId) =>
      (database.update(database.unifiedTreatmentLegacyMappings)..where(
            (row) =>
                row.userId.equals(userId) &
                row.targetRoutineId.equals(routineId),
          ))
          .write(
            UnifiedTreatmentLegacyMappingsCompanion(
              hasNewClinicalWrites: const Value(true),
              updatedAt: Value(clock.now().toUtc()),
            ),
          );
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../../core/database/drift/app_database.dart';
import '../../../core/services/clock_service.dart';
import '../data/dtos/smart_routine_dtos.dart';
import '../domain/enums/routine_enums.dart';
import '../domain/value_objects/local_date.dart';
import '../domain/value_objects/routine_values.dart';
import '../domain/value_objects/schedule_rule.dart';
import 'unified_treatment_cutover_service.dart';
import 'unified_treatment_migrator.dart';
import 'unified_treatment_rollout.dart';

enum TreatmentSpecialization { medication, vitamin }

enum TreatmentDailyState { pending, taken, skipped }

final class TreatmentScheduleInput {
  const TreatmentScheduleInput({
    required this.time,
    this.reminderEnabled = true,
  });

  final TimeOfDayValue time;
  final bool reminderEnabled;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

LocalDate _localDate(String value) {
  final date = DateTime.parse(value);
  return LocalDate(year: date.year, month: date.month, day: date.day);
}

final class TreatmentWriteCommand {
  TreatmentWriteCommand({
    required this.id,
    required this.name,
    required this.category,
    required this.mode,
    required this.durationType,
    required this.effectiveFrom,
    required Iterable<TreatmentScheduleInput> schedules,
    this.weekdays = const <int>{},
    this.effectiveUntil,
    this.singleDoseAt,
    this.dosage,
    this.notes,
  }) : schedules = List<TreatmentScheduleInput>.unmodifiable(schedules) {
    if (name.trim().isEmpty) throw ArgumentError.value(name, 'name');
    if (mode == RoutinePlanMode.asNeeded && this.schedules.isNotEmpty) {
      throw ArgumentError('PRN treatment cannot contain recurring schedules.');
    }
    if (mode == RoutinePlanMode.scheduled &&
        durationType != PlanDurationType.singleDose &&
        this.schedules.isEmpty) {
      throw ArgumentError('Scheduled treatment requires at least one time.');
    }
    if (durationType == PlanDurationType.bounded && effectiveUntil == null) {
      throw ArgumentError('Bounded treatment requires an end date.');
    }
    if (durationType == PlanDurationType.singleDose && singleDoseAt == null) {
      throw ArgumentError('Single dose treatment requires a date and time.');
    }
  }

  final String id;
  final String name;
  final RoutineCategory category;
  final RoutinePlanMode mode;
  final PlanDurationType durationType;
  final LocalDate effectiveFrom;
  final LocalDate? effectiveUntil;
  final DateTime? singleDoseAt;
  final List<TreatmentScheduleInput> schedules;
  final Set<int> weekdays;
  final String? dosage;
  final String? notes;
}

final class TreatmentItemSnapshot {
  const TreatmentItemSnapshot({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.mode,
    required this.durationType,
    required this.effectiveFrom,
    required this.schedules,
    required this.weekdays,
    required this.revision,
    this.effectiveUntil,
    this.dosage,
    this.notes,
  });

  final String id;
  final String name;
  final RoutineCategory category;
  final RoutineStatus status;
  final RoutinePlanMode mode;
  final PlanDurationType durationType;
  final LocalDate effectiveFrom;
  final LocalDate? effectiveUntil;
  final List<TreatmentScheduleInput> schedules;
  final Set<int> weekdays;
  final int revision;
  final String? dosage;
  final String? notes;
}

final class TreatmentChangeImpact {
  const TreatmentChangeImpact({
    required this.createsRevision,
    required this.pastOccurrencesPreserved,
    required this.futureNotificationsReconciled,
  });

  final bool createsRevision;
  final bool pastOccurrencesPreserved;
  final bool futureNotificationsReconciled;
}

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

final class TreatmentEventSnapshot {
  const TreatmentEventSnapshot({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.recordedAt,
    required this.origin,
    required this.isInvalidated,
    this.note,
  });

  final String id;
  final String type;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String origin;
  final bool isInvalidated;
  final String? note;
}

final class TreatmentConflictSnapshot {
  const TreatmentConflictSnapshot({
    required this.occurrenceId,
    required this.impact,
    required this.versions,
  });

  final String occurrenceId;
  final String impact;
  final List<TreatmentEventSnapshot> versions;
}

final class TreatmentRevisionSnapshot {
  const TreatmentRevisionSnapshot({
    required this.revision,
    required this.category,
    required this.effectiveFrom,
    required this.createdAt,
    this.effectiveUntil,
    this.replacedAt,
  });

  final int revision;
  final RoutineCategory category;
  final String effectiveFrom;
  final String? effectiveUntil;
  final DateTime createdAt;
  final DateTime? replacedAt;
}

final class TreatmentPauseSnapshot {
  const TreatmentPauseSnapshot({required this.startsAt, this.endsAt});

  final DateTime startsAt;
  final DateTime? endsAt;
}

final class TreatmentDetailSnapshot {
  const TreatmentDetailSnapshot({
    required this.item,
    required this.revisions,
    required this.events,
    required this.pauses,
    required this.conflicts,
  });

  final TreatmentItemSnapshot item;
  final List<TreatmentRevisionSnapshot> revisions;
  final List<TreatmentEventSnapshot> events;
  final List<TreatmentPauseSnapshot> pauses;
  final List<TreatmentConflictSnapshot> conflicts;
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
    final latestPlanIdRows = await database
        .customSelect(
          '''
      SELECT plan.id
      FROM routine_plan_records AS plan
      INNER JOIN (
        SELECT routine_id, MAX(revision) AS revision
        FROM routine_plan_records
        WHERE user_id = ? AND category = ? AND deleted_at IS NULL
        GROUP BY routine_id
      ) AS latest
        ON latest.routine_id = plan.routine_id
       AND latest.revision = plan.revision
      WHERE plan.user_id = ? AND plan.category = ? AND plan.deleted_at IS NULL
      ORDER BY plan.routine_id ASC
      ''',
          variables: [
            Variable<String>(userId),
            Variable<String>(kind.name),
            Variable<String>(userId),
            Variable<String>(kind.name),
          ],
          readsFrom: {database.routinePlanRecords},
        )
        .get();
    final latestPlanIds = latestPlanIdRows
        .map((row) => row.read<String>('id'))
        .toList(growable: false);
    if (latestPlanIds.isEmpty) return const [];
    final plans =
        await (database.select(database.routinePlanRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.id.isIn(latestPlanIds) &
                  row.deletedAt.isNull(),
            ))
            .get();
    final latestPlanByRoutine = {
      for (final plan in plans) plan.routineId: plan,
    };
    final routineIds = latestPlanByRoutine.keys.toList(growable: false);
    final routines =
        await (database.select(database.smartRoutineRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.id.isIn(routineIds) &
                    row.deletedAt.isNull() &
                    row.status.isNotValue('archived'),
              )
              ..orderBy([
                (row) => OrderingTerm.asc(row.displayName),
                (row) => OrderingTerm.asc(row.id),
              ]))
            .get();
    if (routines.isEmpty) return const [];
    final planIds = latestPlanByRoutine.values
        .map((value) => value.id)
        .toList(growable: false);
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

  Future<List<TreatmentItemSnapshot>> listItems() async {
    await _prepare(requireWrite: false);
    final routines =
        await (database.select(database.smartRoutineRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.deletedAt.isNull() &
                    row.status.isNotValue('archived'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.displayName)]))
            .get();
    final result = <TreatmentItemSnapshot>[];
    for (final routine in routines) {
      final plan = await _latestPlan(routine.id);
      if (plan == null) continue;
      final schedules = await _schedulesFor(plan.id);
      final decoded = schedules.map(
        (row) =>
            (row: row, rule: const ScheduleRuleCodec().decode(row.ruleJson)),
      );
      final times = <TreatmentScheduleInput>[];
      final selectedWeekdays = <int>{};
      for (final value in decoded) {
        final ruleTimes = switch (value.rule) {
          DailyAtTimesRule(:final times) => times,
          SpecificWeekdaysAtTimesRule(
            :final times,
            weekdays: final ruleWeekdays,
          ) =>
            () {
              selectedWeekdays.addAll(ruleWeekdays.values);
              return times;
            }(),
          _ => const <TimeOfDayValue>[],
        };
        times.addAll(
          ruleTimes.map(
            (time) => TreatmentScheduleInput(
              time: time,
              reminderEnabled: value.row.reminderPreference == 'enabled',
            ),
          ),
        );
      }
      times.sort((left, right) => left.time.compareTo(right.time));
      result.add(
        TreatmentItemSnapshot(
          id: routine.id,
          name: routine.displayName,
          category: RoutineCategory.values.byName(plan.category),
          status: RoutineStatus.values.byName(routine.status),
          mode: RoutinePlanMode.values.byName(plan.mode),
          durationType: PlanDurationType.values.byName(plan.durationType),
          effectiveFrom: _localDate(plan.effectiveFrom),
          effectiveUntil: plan.effectiveUntil == null
              ? null
              : _localDate(plan.effectiveUntil!),
          schedules: List.unmodifiable(times),
          weekdays: Set.unmodifiable(selectedWeekdays),
          revision: plan.revision,
          dosage: plan.doseOriginalText ?? _dose(plan),
          notes: routine.personalNotes,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<TreatmentDetailSnapshot> detail(String routineId) async {
    final item = (await listItems()).where((value) => value.id == routineId);
    if (item.isEmpty) throw StateError('routine_not_found');
    final plans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) & row.routineId.equals(routineId),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    final pauses =
        await (database.select(database.routinePauseRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.equals(routineId) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startsAt)]))
            .get();
    final eventRows =
        await (database.select(database.routineAdherenceEventRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) & row.routineId.equals(routineId),
              )
              ..orderBy([
                (row) => OrderingTerm.desc(row.occurredAtUtc),
                (row) => OrderingTerm.desc(row.id),
              ]))
            .get();
    final invalidated = eventRows
        .where(
          (event) =>
              event.type == 'correction' &&
              event.correctionAction == 'invalidate' &&
              event.referencedEventId != null,
        )
        .map((event) => event.referencedEventId!)
        .toSet();
    TreatmentEventSnapshot project(RoutineAdherenceEventRecord event) =>
        TreatmentEventSnapshot(
          id: event.id,
          type: event.type,
          occurredAt: event.occurredAtUtc,
          recordedAt: event.recordedAtUtc,
          origin: event.syncStatus == 'synced' ? 'Remoto' : 'Este aparelho',
          isInvalidated: invalidated.contains(event.id),
          note: event.note,
        );
    final projectedEvents = eventRows.map(project).toList(growable: false);
    final terminalByOccurrence = <String, List<RoutineAdherenceEventRecord>>{};
    for (final event in eventRows) {
      if ((event.type == 'taken' || event.type == 'skipped') &&
          !invalidated.contains(event.id)) {
        terminalByOccurrence
            .putIfAbsent(event.occurrenceId, () => [])
            .add(event);
      }
    }
    final conflicts = terminalByOccurrence.entries
        .where(
          (entry) => entry.value.map((event) => event.type).toSet().length > 1,
        )
        .map(
          (entry) => TreatmentConflictSnapshot(
            occurrenceId: entry.key,
            impact:
                'O histórico e os indicadores permanecem em revisão até você escolher o registro correto.',
            versions: entry.value.map(project).toList(growable: false),
          ),
        )
        .toList(growable: false);
    return TreatmentDetailSnapshot(
      item: item.single,
      revisions: plans
          .map(
            (plan) => TreatmentRevisionSnapshot(
              revision: plan.revision,
              category: RoutineCategory.values.byName(plan.category),
              effectiveFrom: plan.effectiveFrom,
              effectiveUntil: plan.effectiveUntil,
              createdAt: plan.createdAt,
              replacedAt: plan.replacedAt,
            ),
          )
          .toList(growable: false),
      events: projectedEvents,
      pauses: pauses
          .map(
            (pause) => TreatmentPauseSnapshot(
              startsAt: pause.startsAt,
              endsAt: pause.endsAt,
            ),
          )
          .toList(growable: false),
      conflicts: conflicts,
    );
  }

  Future<void> registerPrnUse({
    required String routineId,
    required DateTime occurredAt,
    String? note,
  }) async {
    await _prepare(requireWrite: true);
    final routine =
        await (database.select(database.smartRoutineRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.id.equals(routineId) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    final plan = await _latestPlan(routineId);
    if (routine == null || routine.status != RoutineStatus.active.name) {
      throw StateError('routine_not_active');
    }
    if (plan == null || plan.mode != RoutinePlanMode.asNeeded.name) {
      throw StateError('routine_not_prn');
    }
    final schedules = await _schedulesFor(plan.id);
    final schedule = schedules.length == 1 ? schedules.single : null;
    final recordedAt = clock.now().toUtc();
    final usedAt = occurredAt.toUtc();
    final occurrenceId = _uuid.v5(
      _namespace,
      'prn|$userId|$routineId|${usedAt.toIso8601String()}|${recordedAt.toIso8601String()}',
    );
    final local = occurredAt.toLocal();
    await database.transaction(() async {
      await database
          .into(database.routineOccurrenceRecords)
          .insert(
            RoutineOccurrenceRecordsCompanion.insert(
              id: occurrenceId,
              userId: userId,
              routineId: routineId,
              planId: plan.id,
              scheduleId: Value(schedule?.id),
              origin: RoutineOccurrenceOrigin.adHocAsNeeded.name,
              status: RoutineOccurrenceStatus.expected.name,
              originalClinicalDate: _date(local),
              originalLocalHour: local.hour,
              originalLocalMinute: local.minute,
              originalTimeZone: schedule?.timeZone ?? await _timeZone(),
              expectationKind: 'asNeeded',
              sequence: 0,
              originalScheduledFor: usedAt,
              originalWindowStartsAt: usedAt,
              originalOnTimeEndsAt: usedAt,
              originalWindowEndsAt: usedAt,
              scheduledFor: usedAt,
              windowStartsAt: usedAt,
              onTimeEndsAt: usedAt,
              windowEndsAt: usedAt,
              createdAt: recordedAt,
              updatedAt: recordedAt,
              syncStatus: 'pendingCreate',
            ),
          );
      await _appendEvent(
        await (database.select(database.routineOccurrenceRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(occurrenceId),
            ))
            .getSingle(),
        id: _uuid.v5(_namespace, 'prn-event|$occurrenceId'),
        type: 'taken',
        occurredAt: usedAt,
        recordedAt: recordedAt,
        note: _optional(note),
      );
    });
    await _markNewClinicalWrite(routineId);
  }

  Future<void> resolveConflict({
    required String occurrenceId,
    required String keepEventId,
  }) async {
    await _prepare(requireWrite: true);
    final events =
        await (database.select(database.routineAdherenceEventRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.occurrenceId.equals(occurrenceId),
            ))
            .get();
    final keptValues = events.where((event) => event.id == keepEventId);
    final kept = keptValues.length == 1 ? keptValues.single : null;
    final occurrence =
        await (database.select(database.routineOccurrenceRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(occurrenceId),
            ))
            .getSingleOrNull();
    if (kept == null || occurrence == null) {
      throw StateError('conflict_not_found');
    }
    final rejected = events.where(
      (event) =>
          event.id != keepEventId &&
          (event.type == 'taken' || event.type == 'skipped'),
    );
    final now = clock.now().toUtc();
    for (final event in rejected) {
      await _appendEvent(
        occurrence,
        id: _uuid.v5(
          _namespace,
          'resolve|$occurrenceId|keep:$keepEventId|drop:${event.id}',
        ),
        type: 'correction',
        occurredAt: now,
        recordedAt: now,
        referencedEventId: event.id,
        correctionAction: 'invalidate',
      );
    }
    await _markNewClinicalWrite(occurrence.routineId);
  }

  Future<TreatmentChangeImpact> impactFor(TreatmentWriteCommand command) async {
    await _prepare(requireWrite: false);
    final existing =
        await (database.select(database.smartRoutineRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(command.id),
            ))
            .getSingleOrNull();
    return TreatmentChangeImpact(
      createsRevision: existing != null,
      pastOccurrencesPreserved: true,
      futureNotificationsReconciled: true,
    );
  }

  Future<void> write(TreatmentWriteCommand command) async {
    await _prepare(requireWrite: true);
    final routine =
        await (database.select(database.smartRoutineRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(command.id),
            ))
            .getSingleOrNull();
    final current = routine == null ? null : await _latestPlan(routine.id);
    final now = clock.now().toUtc();
    final revision = (current?.revision ?? 0) + 1;
    final planId = _uuid.v5(
      _namespace,
      'manual|$userId|${command.id}|plan|$revision',
    );
    final timeZone = await _timeZone();
    await database.transaction(() async {
      if (routine == null) {
        await database
            .into(database.smartRoutineRecords)
            .insert(
              SmartRoutineRecordsCompanion.insert(
                id: command.id,
                userId: userId,
                category: command.category.name,
                displayName: command.name.trim(),
                status: 'active',
                source: 'manual',
                personalNotes: Value(_optional(command.notes)),
                createdAt: now,
                updatedAt: now,
                syncStatus: 'pendingCreate',
              ),
            );
      } else {
        await (database.update(database.smartRoutineRecords)..where(
              (row) => row.userId.equals(userId) & row.id.equals(command.id),
            ))
            .write(
              SmartRoutineRecordsCompanion(
                displayName: Value(command.name.trim()),
                category: Value(command.category.name),
                personalNotes: Value(_optional(command.notes)),
                status: const Value('active'),
                updatedAt: Value(now),
                syncStatus: const Value('pendingUpdate'),
              ),
            );
        if (current == null) throw StateError('routine_plan_missing');
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
      }
      await database
          .into(database.routinePlanRecords)
          .insert(
            RoutinePlanRecordsCompanion.insert(
              id: planId,
              userId: userId,
              routineId: command.id,
              revision: revision,
              category: Value(command.category.name),
              mode: command.mode.name,
              durationType: command.durationType.name,
              effectiveFrom: command.effectiveFrom.toString(),
              effectiveUntil: Value(command.effectiveUntil?.toString()),
              doseOriginalText: Value(_optional(command.dosage)),
              activatedAt: Value(now),
              previousPlanId: Value(current?.id),
              createdAt: now,
              updatedAt: now,
              syncStatus: 'pendingCreate',
            ),
          );
      final rules = _rulesFor(command);
      for (var index = 0; index < rules.length; index++) {
        final entry = rules[index];
        await database
            .into(database.routineScheduleRecords)
            .insert(
              RoutineScheduleRecordsCompanion.insert(
                id: _uuid.v5(
                  _namespace,
                  'manual|$userId|${command.id}|schedule|$revision|$index',
                ),
                userId: userId,
                routineId: command.id,
                planId: planId,
                ruleJson: const ScheduleRuleCodec().encode(entry.$1),
                timeZone: timeZone,
                reminderPreference: entry.$2 ? 'enabled' : 'disabled',
                earlyToleranceSeconds: 0,
                onTimeToleranceSeconds: 1800,
                lateToleranceSeconds: 43200,
                isEnabled: true,
                displayOrder: index,
                createdAt: now,
                updatedAt: now,
                syncStatus: 'pendingCreate',
              ),
            );
      }
    });
    await _markNewClinicalWrite(command.id);
  }

  Future<void> pause(String id) => _changeStatus(id, RoutineStatus.paused);

  Future<void> resume(String id) => _changeStatus(id, RoutineStatus.active);

  Future<void> complete(String id) =>
      _changeStatus(id, RoutineStatus.completed);

  Future<void> softDelete(String id) async {
    await _prepare(requireWrite: true);
    final now = clock.now().toUtc();
    await (database.update(
      database.smartRoutineRecords,
    )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
      SmartRoutineRecordsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value('pendingDelete'),
      ),
    );
    await _markNewClinicalWrite(id);
  }

  Future<RoutinePlanRecord?> _latestPlan(String routineId) {
    return (database.select(database.routinePlanRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) &
                row.routineId.equals(routineId) &
                row.deletedAt.isNull(),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.revision)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<RoutineScheduleRecord>> _schedulesFor(String planId) {
    return (database.select(database.routineScheduleRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) &
                row.planId.equals(planId) &
                row.isEnabled.equals(true) &
                row.deletedAt.isNull(),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.displayOrder)]))
        .get();
  }

  List<(ScheduleRule, bool)> _rulesFor(TreatmentWriteCommand command) {
    if (command.mode == RoutinePlanMode.asNeeded) {
      return const [(AsNeededRule(), false)];
    }
    if (command.durationType == PlanDurationType.singleDose) {
      return [(SingleDoseRule(command.singleDoseAt!), true)];
    }
    return command.schedules
        .map<(ScheduleRule, bool)>((schedule) {
          final rule = command.weekdays.isEmpty
              ? DailyAtTimesRule([schedule.time])
              : SpecificWeekdaysAtTimesRule(
                  weekdays: WeekdaySet(command.weekdays),
                  times: [schedule.time],
                );
          return (rule, schedule.reminderEnabled);
        })
        .toList(growable: false);
  }

  Future<void> _changeStatus(String id, RoutineStatus next) async {
    await _prepare(requireWrite: true);
    final routine =
        await (database.select(database.smartRoutineRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.id.equals(id) &
                  row.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (routine == null) throw StateError('routine_not_found');
    final current = RoutineStatus.values.byName(routine.status);
    const transitions = <RoutineStatus, Set<RoutineStatus>>{
      RoutineStatus.active: {RoutineStatus.paused, RoutineStatus.completed},
      RoutineStatus.paused: {RoutineStatus.active, RoutineStatus.completed},
      RoutineStatus.completed: {},
      RoutineStatus.canceled: {},
      RoutineStatus.archived: {},
    };
    if (current == next) return;
    if (!transitions[current]!.contains(next)) {
      throw StateError('invalid_routine_status_transition');
    }
    final now = clock.now().toUtc();
    await database.transaction(() async {
      await (database.update(
        database.smartRoutineRecords,
      )..where((row) => row.userId.equals(userId) & row.id.equals(id))).write(
        SmartRoutineRecordsCompanion(
          status: Value(next.name),
          updatedAt: Value(now),
          syncStatus: const Value('pendingUpdate'),
        ),
      );
      if (next == RoutineStatus.paused) {
        await database
            .into(database.routinePauseRecords)
            .insert(
              RoutinePauseRecordsCompanion.insert(
                id: _uuid.v5(
                  _namespace,
                  'pause|$userId|$id|${now.toIso8601String()}',
                ),
                userId: userId,
                routineId: id,
                scope: 'routine',
                startsAt: now,
                createdAt: now,
                updatedAt: now,
                syncStatus: 'pendingCreate',
              ),
            );
      } else if (current == RoutineStatus.paused) {
        final openPauses =
            await (database.select(database.routinePauseRecords)..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.routineId.equals(id) &
                      row.endsAt.isNull() &
                      row.deletedAt.isNull(),
                ))
                .get();
        for (final pause in openPauses) {
          await (database.update(database.routinePauseRecords)..where(
                (row) => row.userId.equals(userId) & row.id.equals(pause.id),
              ))
              .write(
                RoutinePauseRecordsCompanion(
                  endsAt: Value(now),
                  updatedAt: Value(now),
                  syncStatus: const Value('pendingUpdate'),
                ),
              );
        }
      }
    });
    await _markNewClinicalWrite(id);
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
    String? note,
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
          note: Value(note),
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

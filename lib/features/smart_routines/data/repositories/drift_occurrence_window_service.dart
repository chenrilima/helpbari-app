import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../application/routine_notification_projection.dart';
import '../../domain/entities/routine_occurrence.dart';
import '../../domain/enums/routine_enums.dart';
import '../../domain/value_objects/local_date.dart';
import '../../domain/value_objects/routine_values.dart';
import '../../domain/value_objects/typed_ids.dart';

class DriftOccurrenceWindowService {
  const DriftOccurrenceWindowService({
    required this.database,
    required this.userId,
    this.uuid = const Uuid(),
  });
  final AppDatabase database;
  final String userId;
  final Uuid uuid;
  static const _namespace = 'a5ae6e59-1007-5162-8a93-d938467625ac';

  Future<List<RoutineNotificationProjection>> materializeAndProject({
    required DateTime fromUtc,
    required DateTime untilUtc,
  }) async {
    final routines =
        await (database.select(database.smartRoutineRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.status.equals('active') &
                  row.deletedAt.isNull(),
            ))
            .get();
    final routineIds = routines.map((value) => value.id).toSet();
    final plans =
        await (database.select(database.routinePlanRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.routineId.isIn(routineIds) &
                  row.replacedAt.isNull() &
                  row.deletedAt.isNull() &
                  row.validationStatus.equals('confirmed'),
            ))
            .get();
    final pauses = routineIds.isEmpty
        ? const <RoutinePauseRecord>[]
        : await (database.select(database.routinePauseRecords)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.routineId.isIn(routineIds) &
                    row.deletedAt.isNull(),
              ))
              .get();
    final planById = {for (final plan in plans) plan.id: plan};
    final schedules = planById.isEmpty
        ? const <RoutineScheduleRecord>[]
        : await (database.select(database.routineScheduleRecords)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.planId.isIn(planById.keys) &
                    row.isEnabled.equals(true) &
                    row.reminderPreference.equals('enabled') &
                    row.deletedAt.isNull(),
              ))
              .get();
    for (final schedule in schedules) {
      final plan = planById[schedule.planId]!;
      await _materializeSchedule(plan, schedule, pauses, fromUtc, untilUtc);
    }
    final rows =
        await (database.select(database.routineOccurrenceRecords)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.scheduledFor.isBiggerOrEqualValue(fromUtc) &
                  row.scheduledFor.isSmallerThanValue(untilUtc) &
                  row.deletedAt.isNull() &
                  row.status.isNotIn(['canceled', 'paused', 'notApplicable']),
            ))
            .get();
    final events = rows.isEmpty
        ? const <RoutineAdherenceEventRecord>[]
        : await (database.select(database.routineAdherenceEventRecords)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.occurrenceId.isIn(rows.map((value) => value.id)) &
                    row.type.isIn(['taken', 'skipped', 'canceled']),
              ))
              .get();
    final resolved = events.map((value) => value.occurrenceId).toSet();
    return rows
        .where((row) => !resolved.contains(row.id))
        .map(
          (row) => RoutineNotificationProjection.fromOccurrence(
            occurrence: _entity(row),
            userId: userId,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _materializeSchedule(
    RoutinePlanRecord plan,
    RoutineScheduleRecord schedule,
    List<RoutinePauseRecord> pauses,
    DateTime fromUtc,
    DateTime untilUtc,
  ) async {
    final rule = Map<String, dynamic>.from(
      jsonDecode(schedule.ruleJson) as Map,
    );
    final times = (rule['times'] as List? ?? const <Object>[]).cast<String>();
    if (times.isEmpty ||
        !{'dailyAtTimes', 'specificWeekdaysAtTimes'}.contains(rule['type'])) {
      return;
    }
    tz.Location location;
    try {
      location = tz.getLocation(schedule.timeZone);
    } catch (_) {
      location = tz.UTC;
    }
    final localFrom = tz.TZDateTime.from(fromUtc, location);
    final localUntil = tz.TZDateTime.from(untilUtc, location);
    final first = DateTime(localFrom.year, localFrom.month, localFrom.day);
    final last = DateTime(localUntil.year, localUntil.month, localUntil.day);
    final effectiveFrom = DateTime.parse(plan.effectiveFrom);
    final effectiveUntil = plan.effectiveUntil == null
        ? null
        : DateTime.parse(plan.effectiveUntil!);
    for (
      var day = first;
      !day.isAfter(last);
      day = day.add(const Duration(days: 1))
    ) {
      if (day.isBefore(effectiveFrom) ||
          (effectiveUntil != null && day.isAfter(effectiveUntil))) {
        continue;
      }
      if (rule['type'] == 'specificWeekdaysAtTimes' &&
          !(rule['weekdays'] as List).cast<int>().contains(day.weekday)) {
        continue;
      }
      for (var sequence = 0; sequence < times.length; sequence++) {
        final parts = times[sequence].split(':');
        final local = tz.TZDateTime(
          location,
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final scheduled = local.toUtc();
        if (scheduled.isBefore(fromUtc) || !scheduled.isBefore(untilUtc)) {
          continue;
        }
        if (pauses.any(
          (pause) =>
              pause.routineId == plan.routineId &&
              (pause.planId == null || pause.planId == plan.id) &&
              !scheduled.isBefore(pause.startsAt) &&
              (pause.endsAt == null || scheduled.isBefore(pause.endsAt!)),
        )) {
          continue;
        }
        final id = uuid.v5(
          _namespace,
          'occurrence-v1|$userId|${schedule.id}|${_date(day)}|${times[sequence]}|$sequence',
        );
        final existing =
            await (database.select(database.routineOccurrenceRecords)..where(
                  (row) => row.userId.equals(userId) & row.id.equals(id),
                ))
                .getSingleOrNull();
        if (existing != null) continue;
        await database
            .into(database.routineOccurrenceRecords)
            .insert(
              RoutineOccurrenceRecordsCompanion.insert(
                id: id,
                userId: userId,
                routineId: plan.routineId,
                planId: plan.id,
                scheduleId: Value(schedule.id),
                origin: 'generated',
                status: 'expected',
                originalClinicalDate: _date(day),
                originalLocalHour: int.parse(parts[0]),
                originalLocalMinute: int.parse(parts[1]),
                originalTimeZone: schedule.timeZone,
                expectationKind: 'recurringExpectation',
                sequence: sequence,
                originalScheduledFor: scheduled,
                originalWindowStartsAt: scheduled.subtract(
                  Duration(seconds: schedule.earlyToleranceSeconds),
                ),
                originalOnTimeEndsAt: scheduled.add(
                  Duration(seconds: schedule.onTimeToleranceSeconds),
                ),
                originalWindowEndsAt: scheduled.add(
                  Duration(seconds: schedule.lateToleranceSeconds),
                ),
                scheduledFor: scheduled,
                windowStartsAt: scheduled.subtract(
                  Duration(seconds: schedule.earlyToleranceSeconds),
                ),
                onTimeEndsAt: scheduled.add(
                  Duration(seconds: schedule.onTimeToleranceSeconds),
                ),
                windowEndsAt: scheduled.add(
                  Duration(seconds: schedule.lateToleranceSeconds),
                ),
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
                syncStatus: 'pendingCreate',
              ),
            );
      }
    }
  }

  RoutineOccurrence _entity(RoutineOccurrenceRecord row) => RoutineOccurrence(
    occurrenceId: RoutineOccurrenceId(row.id),
    routineId: RoutineId(row.routineId),
    planId: RoutinePlanId(row.planId),
    scheduleId: row.scheduleId == null
        ? null
        : RoutineScheduleId(row.scheduleId!),
    origin: RoutineOccurrenceOrigin.values.byName(row.origin),
    originalWindow: OccurrenceWindow(
      scheduledFor: row.originalScheduledFor,
      windowStartsAt: row.originalWindowStartsAt,
      onTimeEndsAt: row.originalOnTimeEndsAt,
      windowEndsAt: row.originalWindowEndsAt,
    ),
    currentWindow: OccurrenceWindow(
      scheduledFor: row.scheduledFor,
      windowStartsAt: row.windowStartsAt,
      onTimeEndsAt: row.onTimeEndsAt,
      windowEndsAt: row.windowEndsAt,
    ),
    status: RoutineOccurrenceStatus.values.byName(row.status),
    originalClinicalDate: LocalDate.fromDateTime(
      DateTime.parse(row.originalClinicalDate),
    ),
    originalLocalTime: TimeOfDayValue(
      hour: row.originalLocalHour,
      minute: row.originalLocalMinute,
    ),
    originalTimeZone: IanaTimeZone(row.originalTimeZone),
    expectationKind: ExpectationKind.values.byName(row.expectationKind),
    sequence: row.sequence,
  );

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

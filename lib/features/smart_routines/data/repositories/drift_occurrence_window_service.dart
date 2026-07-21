import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/clock_service.dart';
import '../../application/routine_notification_projection.dart';
import '../../domain/entities/routine_occurrence.dart';
import '../../domain/enums/routine_enums.dart';
import '../../domain/value_objects/local_date.dart';
import '../../domain/value_objects/routine_values.dart';
import '../../domain/value_objects/typed_ids.dart';
import '../../domain/value_objects/occurrence_blueprint.dart';
import '../../domain/services/routine_occurrence_materializer.dart';
import '../../domain/services/schedule_instant_resolver.dart';

class DriftOccurrenceWindowService {
  const DriftOccurrenceWindowService({
    required this.database,
    required this.userId,
    required this.clock,
    this.materializer = const RoutineOccurrenceMaterializer(),
  });
  final AppDatabase database;
  final String userId;
  final ClockService clock;
  final RoutineOccurrenceMaterializer materializer;

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
                    row.deletedAt.isNull(),
              ))
              .get();
    for (final schedule in schedules) {
      final plan = planById[schedule.planId]!;
      try {
        await _materializeSchedule(plan, schedule, pauses, fromUtc, untilUtc);
      } on FormatException {
        continue;
      } on tz.LocationNotFoundException {
        continue;
      }
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
    final reminderScheduleIds = schedules
        .where((value) => value.reminderPreference == 'enabled')
        .map((value) => value.id)
        .toSet();
    return rows
        .where(
          (row) =>
              !resolved.contains(row.id) &&
              reminderScheduleIds.contains(row.scheduleId),
        )
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
    final singleDoseAt = rule['type'] == 'singleDose'
        ? DateTime.parse(rule['scheduledAt'] as String)
        : null;
    final times = singleDoseAt == null
        ? (rule['times'] as List? ?? const <Object>[]).cast<String>()
        : <String>[
            '${singleDoseAt.hour.toString().padLeft(2, '0')}:'
                '${singleDoseAt.minute.toString().padLeft(2, '0')}',
          ];
    final isEveryHours = rule['type'] == 'everyNHours';
    if ((!isEveryHours && times.isEmpty) ||
        !{
          'dailyAtTimes',
          'specificWeekdaysAtTimes',
          'everyNDays',
          'weekly',
          'monthly',
          'singleDose',
          'everyNHours',
        }.contains(rule['type'])) {
      return;
    }
    final first = DateTime.utc(fromUtc.year, fromUtc.month, fromUtc.day - 1);
    final last = DateTime.utc(untilUtc.year, untilUtc.month, untilUtc.day + 1);
    final effectiveFrom = DateTime.parse(plan.effectiveFrom);
    final effectiveUntil = plan.effectiveUntil == null
        ? null
        : DateTime.parse(plan.effectiveUntil!);
    final blueprints = <OccurrenceBlueprint>[];
    final absolute = <OccurrenceBlueprint, ResolvedLocalScheduleTime>{};
    if (isEveryHours) {
      final anchor = DateTime.parse(rule['anchorAtUtc'] as String).toUtc();
      final interval = Duration(hours: rule['intervalHours'] as int);
      final location = schedule.timeZone == 'UTC'
          ? tz.UTC
          : tz.getLocation(schedule.timeZone);
      final elapsed = fromUtc.isAfter(anchor)
          ? fromUtc.difference(anchor).inMicroseconds
          : 0;
      var sequence =
          (elapsed + interval.inMicroseconds - 1) ~/ interval.inMicroseconds;
      while (true) {
        final instant = anchor.add(interval * sequence);
        if (!instant.isBefore(untilUtc)) break;
        final local = tz.TZDateTime.from(instant, location);
        final date = LocalDate.fromDateTime(local);
        final time = TimeOfDayValue(hour: local.hour, minute: local.minute);
        final blueprint = OccurrenceBlueprint(
          routineId: RoutineId(plan.routineId),
          planId: RoutinePlanId(plan.id),
          scheduleId: RoutineScheduleId(schedule.id),
          clinicalDate: date,
          localTime: time,
          timeZone: IanaTimeZone(schedule.timeZone),
          expectationKind: ExpectationKind.recurringExpectation,
          sequence: sequence,
          originalLocalDate: date,
          originalLocalTime: time,
          sourceRuleType: ScheduleFrequencyType.everyNHours,
          scheduleDisplayOrder: schedule.displayOrder,
        );
        blueprints.add(blueprint);
        absolute[blueprint] = ResolvedLocalScheduleTime(
          instantUtc: instant,
          timeZone: blueprint.timeZone,
          offset: local.timeZoneOffset,
          state: ScheduleInstantResolutionState.exact,
          requestedDate: date,
          requestedTime: time,
          resolvedDate: date,
          resolvedTime: time,
          diagnostic: 'absolute_interval_slot',
        );
        sequence++;
      }
    }
    for (
      var day = first;
      !day.isAfter(last);
      day = day.add(const Duration(days: 1))
    ) {
      if (isEveryHours) break;
      if (day.isBefore(effectiveFrom) ||
          (effectiveUntil != null && day.isAfter(effectiveUntil))) {
        continue;
      }
      if (rule['type'] == 'specificWeekdaysAtTimes' &&
          !(rule['weekdays'] as List).cast<int>().contains(day.weekday)) {
        continue;
      }
      if (rule['type'] == 'weekly' && rule['weekday'] != day.weekday) {
        continue;
      }
      if (rule['type'] == 'monthly' && rule['dayOfMonth'] != day.day) {
        continue;
      }
      if (singleDoseAt != null &&
          (singleDoseAt.year != day.year ||
              singleDoseAt.month != day.month ||
              singleDoseAt.day != day.day)) {
        continue;
      }
      if (rule['type'] == 'everyNDays') {
        final anchor = DateTime.parse(rule['anchorDate'] as String);
        final interval = rule['intervalDays'] as int;
        if (day.difference(anchor).inDays % interval != 0) continue;
      }
      for (var sequence = 0; sequence < times.length; sequence++) {
        final parts = times[sequence].split(':');
        final date = LocalDate.fromDateTime(day);
        final time = TimeOfDayValue(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        blueprints.add(
          OccurrenceBlueprint(
            routineId: RoutineId(plan.routineId),
            planId: RoutinePlanId(plan.id),
            scheduleId: RoutineScheduleId(schedule.id),
            clinicalDate: date,
            localTime: time,
            timeZone: IanaTimeZone(schedule.timeZone),
            expectationKind: singleDoseAt == null
                ? ExpectationKind.recurringExpectation
                : ExpectationKind.singleExpectation,
            sequence: sequence,
            originalLocalDate: date,
            originalLocalTime: time,
            sourceRuleType: switch (rule['type']) {
              'dailyAtTimes' => ScheduleFrequencyType.dailyAtTimes,
              'specificWeekdaysAtTimes' =>
                ScheduleFrequencyType.specificWeekdaysAtTimes,
              'everyNDays' => ScheduleFrequencyType.everyNDays,
              'weekly' => ScheduleFrequencyType.weekly,
              'monthly' => ScheduleFrequencyType.monthly,
              'singleDose' => ScheduleFrequencyType.singleDose,
              _ => throw StateError('Unsupported schedule rule.'),
            },
            scheduleDisplayOrder: schedule.displayOrder,
          ),
        );
      }
    }
    final resolved =
        blueprints
            .map(
              (blueprint) => (
                blueprint: blueprint,
                resolution: absolute[blueprint] == null
                    ? materializer.instantResolver.resolve(
                        localDate: blueprint.clinicalDate,
                        localTime: blueprint.localTime,
                        timeZone: blueprint.timeZone,
                      )
                    : ScheduleInstantResolutionResult.resolved(
                        absolute[blueprint]!,
                      ),
              ),
            )
            .where((value) => value.resolution.isResolved)
            .toList()
          ..sort(
            (left, right) => left.resolution.value!.instantUtc.compareTo(
              right.resolution.value!.instantUtc,
            ),
          );
    for (var index = 0; index < resolved.length; index++) {
      final item = resolved[index];
      final scheduled = item.resolution.value!.instantUtc;
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
      final result = materializer.materialize(
        blueprint: item.blueprint,
        windowDefinition: OccurrenceWindowDefinition(
          earlyTolerance: Duration(seconds: schedule.earlyToleranceSeconds),
          onTimeTolerance: Duration(seconds: schedule.onTimeToleranceSeconds),
          lateTolerance: Duration(seconds: schedule.lateToleranceSeconds),
        ),
        preResolved: item.resolution.value,
        nextTargetAtUtc: index + 1 < resolved.length
            ? resolved[index + 1].resolution.value!.instantUtc
            : null,
      );
      if (!result.isMaterialized) continue;
      final occurrence = result.occurrence!;
      final id = occurrence.id;
      final existing =
          await (database.select(database.routineOccurrenceRecords)
                ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
              .getSingleOrNull();
      if (existing != null) continue;
      await database
          .into(database.routineOccurrenceRecords)
          .insert(
            RoutineOccurrenceRecordsCompanion.insert(
              id: id,
              userId: userId,
              routineId: occurrence.routineId.value,
              planId: occurrence.planId.value,
              scheduleId: Value(occurrence.scheduleId!.value),
              origin: occurrence.origin.name,
              status: occurrence.status.name,
              originalClinicalDate: occurrence.originalClinicalDate.toString(),
              originalLocalHour: occurrence.originalLocalTime.hour,
              originalLocalMinute: occurrence.originalLocalTime.minute,
              originalTimeZone: occurrence.originalTimeZone.value,
              expectationKind: occurrence.expectationKind.name,
              sequence: occurrence.sequence,
              originalScheduledFor: occurrence.originalScheduledFor,
              originalWindowStartsAt: occurrence.originalWindow.windowStartsAt,
              originalOnTimeEndsAt: occurrence.originalWindow.onTimeEndsAt,
              originalWindowEndsAt: occurrence.originalWindow.windowEndsAt,
              scheduledFor: occurrence.currentScheduledFor,
              windowStartsAt: occurrence.currentWindow.windowStartsAt,
              onTimeEndsAt: occurrence.currentWindow.onTimeEndsAt,
              windowEndsAt: occurrence.currentWindow.windowEndsAt,
              createdAt: clock.now().toUtc(),
              updatedAt: clock.now().toUtc(),
              syncStatus: 'synced',
            ),
          );
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
      scheduledFor: row.originalScheduledFor.toUtc(),
      windowStartsAt: row.originalWindowStartsAt.toUtc(),
      onTimeEndsAt: row.originalOnTimeEndsAt.toUtc(),
      windowEndsAt: row.originalWindowEndsAt.toUtc(),
    ),
    currentWindow: OccurrenceWindow(
      scheduledFor: row.scheduledFor.toUtc(),
      windowStartsAt: row.windowStartsAt.toUtc(),
      onTimeEndsAt: row.onTimeEndsAt.toUtc(),
      windowEndsAt: row.windowEndsAt.toUtc(),
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
}

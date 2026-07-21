import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/clock_service.dart';
import '../../domain/enums/routine_enums.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/routine_adherence_projector.dart';
import '../../domain/services/treatment_query_models.dart';
import '../../domain/value_objects/local_date.dart';
import '../../domain/value_objects/routine_values.dart';
import '../../domain/value_objects/typed_ids.dart';
import 'drift_occurrence_window_service.dart';

class MaterializingTreatmentAdherenceQueryService
    implements TreatmentAdherenceQueryService {
  const MaterializingTreatmentAdherenceQueryService({
    required this.occurrences,
    required this.delegate,
  });
  final DriftOccurrenceWindowService occurrences;
  final TreatmentAdherenceQueryService delegate;

  @override
  Future<TreatmentAdherenceSummary> summary(
    DateTime start,
    DateTime end,
  ) async {
    await occurrences.materializeAndProject(
      fromUtc: DateTime.utc(
        start.year,
        start.month,
        start.day,
      ).subtract(const Duration(hours: 14)),
      untilUtc: DateTime.utc(
        end.year,
        end.month,
        end.day + 1,
      ).add(const Duration(hours: 14)),
    );
    return delegate.summary(start, end);
  }

  @override
  Future<TodayTreatmentReadModel> today(DateTime date) async {
    await occurrences.materializeAndProject(
      fromUtc: DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).subtract(const Duration(hours: 14)),
      untilUtc: DateTime.utc(
        date.year,
        date.month,
        date.day + 1,
      ).add(const Duration(hours: 14)),
    );
    return delegate.today(date);
  }

  @override
  Future<Map<String, TodayTreatmentReadModel>> days(
    DateTime start,
    DateTime end,
  ) async {
    await occurrences.materializeAndProject(
      fromUtc: DateTime.utc(
        start.year,
        start.month,
        start.day,
      ).subtract(const Duration(hours: 14)),
      untilUtc: DateTime.utc(
        end.year,
        end.month,
        end.day + 1,
      ).add(const Duration(hours: 14)),
    );
    return delegate.days(start, end);
  }
}

class DriftTreatmentAdherenceQueryService
    implements TreatmentAdherenceQueryService {
  const DriftTreatmentAdherenceQueryService({
    required this.database,
    required this.userId,
    required this.clock,
    this.minimumCoverage = .6,
  });
  final AppDatabase database;
  final String userId;
  final ClockService clock;
  final double minimumCoverage;
  static const _projector = RoutineAdherenceProjector();

  @override
  Future<TreatmentAdherenceSummary> summary(
    DateTime start,
    DateTime end,
  ) async {
    final occurrences = await _occurrences(start, end);
    final events = await _events(occurrences.map((value) => value.id));
    final evaluatedAt = clock.now().toUtc();
    final global = _summaryFromRows(occurrences, events, evaluatedAt);
    final routines = await _routinesFor(occurrences);
    final byId = {for (final row in routines) row.id: row};
    final byCategory = <RoutineCategory, TreatmentAdherenceSummary>{};
    for (final category in RoutineCategory.values) {
      final rows = occurrences
          .where(
            (row) =>
                (byId[row.routineId]?.category ?? 'other') == category.name,
          )
          .toList(growable: false);
      if (rows.isEmpty) continue;
      byCategory[category] = _summaryFromRows(rows, events, evaluatedAt);
    }
    return TreatmentAdherenceSummary(
      eligible: global.eligible,
      taken: global.taken,
      takenOnTime: global.takenOnTime,
      skipped: global.skipped,
      missed: global.missed,
      coverage: global.coverage,
      coverageState: global.coverageState,
      origin: global.origin,
      formulaVersion: global.formulaVersion,
      byCategory: Map.unmodifiable(byCategory),
    );
  }

  TreatmentAdherenceSummary _summaryFromRows(
    List<RoutineOccurrenceRecord> occurrences,
    Map<String, List<RoutineAdherenceEventRecord>> events,
    DateTime now,
  ) {
    var taken = 0;
    var onTime = 0;
    var skipped = 0;
    var missed = 0;
    var expected = 0;
    var evaluable = 0;
    for (final row in occurrences) {
      final projection = _projector.project(
        occurrence: _occurrence(row),
        events: (events[row.id] ?? const []).map(_event),
        evaluatedAtUtc: now,
      );
      if (projection.isExcluded) continue;
      expected++;
      if (projection.isInconsistent) continue;
      evaluable++;
      switch (projection.state) {
        case OccurrenceAdherenceState.takenEarly:
          taken++;
        case OccurrenceAdherenceState.takenOnTime:
          taken++;
          onTime++;
        case OccurrenceAdherenceState.takenLate:
          taken++;
        case OccurrenceAdherenceState.skipped:
          skipped++;
        case OccurrenceAdherenceState.missed:
          missed++;
        case OccurrenceAdherenceState.pending:
        case OccurrenceAdherenceState.notApplicable:
        case OccurrenceAdherenceState.inconsistent:
          break;
      }
    }
    final eligible = taken + skipped + missed;
    final coverage = expected == 0 ? 0.0 : evaluable / expected;
    return TreatmentAdherenceSummary(
      eligible: eligible,
      taken: taken,
      takenOnTime: onTime,
      skipped: skipped,
      missed: missed,
      coverage: coverage,
      coverageState: expected == 0
          ? AdherenceCoverageState.unknown
          : coverage >= minimumCoverage
          ? AdherenceCoverageState.complete
          : AdherenceCoverageState.partial,
      origin: TreatmentDataOrigin.smartRoutines,
    );
  }

  @override
  Future<TodayTreatmentReadModel> today(DateTime date) async {
    final values = await days(date, date);
    return values[_date(date)]!;
  }

  @override
  Future<Map<String, TodayTreatmentReadModel>> days(
    DateTime start,
    DateTime end,
  ) async {
    final occurrences = await _occurrences(start, end);
    final events = await _events(occurrences.map((value) => value.id));
    final routines = await _routinesFor(occurrences);
    final byId = {for (final row in routines) row.id: row};
    final occurrenceById = {for (final row in occurrences) row.id: row};
    final evaluatedAt = clock.now().toUtc();
    final items = occurrences.map((occurrence) {
      final projection = _projector.project(
        occurrence: _occurrence(occurrence),
        events: (events[occurrence.id] ?? const []).map(_event),
        evaluatedAtUtc: evaluatedAt,
      );
      final routine = byId[occurrence.routineId];
      return TodayTreatmentOccurrence(
        id: occurrence.id,
        routineId: occurrence.routineId,
        category: RoutineCategory.values.byName(routine?.category ?? 'other'),
        title: routine?.displayName ?? 'Rotina',
        scheduledFor: occurrence.scheduledFor,
        windowEndsAt: occurrence.windowEndsAt,
        state: projection.state,
        operationalState: _operationalState(
          row: occurrence,
          state: projection.state,
          now: evaluatedAt,
        ),
        originalScheduledFor: occurrence.originalScheduledFor,
      );
    }).toList()..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    final itemsByDay = <String, List<TodayTreatmentOccurrence>>{};
    for (final item in items) {
      final occurrence = occurrenceById[item.id]!;
      itemsByDay
          .putIfAbsent(occurrence.originalClinicalDate, () => [])
          .add(item);
    }
    final result = <String, TodayTreatmentReadModel>{};
    for (
      var date = DateTime(start.year, start.month, start.day);
      !date.isAfter(DateTime(end.year, end.month, end.day));
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      final key = _date(date);
      final dayRows = occurrences
          .where((row) => row.originalClinicalDate == key)
          .toList(growable: false);
      final global = _summaryFromRows(dayRows, events, evaluatedAt);
      final categorySummaries = <RoutineCategory, TreatmentAdherenceSummary>{};
      for (final category in RoutineCategory.values) {
        final categoryRows = dayRows
            .where(
              (row) =>
                  (byId[row.routineId]?.category ?? 'other') == category.name,
            )
            .toList(growable: false);
        if (categoryRows.isEmpty) continue;
        categorySummaries[category] = _summaryFromRows(
          categoryRows,
          events,
          evaluatedAt,
        );
      }
      result[key] = TodayTreatmentReadModel(
        date: date,
        occurrences: List.unmodifiable(itemsByDay[key] ?? const []),
        adherence: TreatmentAdherenceSummary(
          eligible: global.eligible,
          taken: global.taken,
          takenOnTime: global.takenOnTime,
          skipped: global.skipped,
          missed: global.missed,
          coverage: global.coverage,
          coverageState: global.coverageState,
          origin: global.origin,
          formulaVersion: global.formulaVersion,
          byCategory: Map.unmodifiable(categorySummaries),
        ),
      );
    }
    return result;
  }

  TreatmentOccurrenceState _operationalState({
    required RoutineOccurrenceRecord row,
    required OccurrenceAdherenceState state,
    required DateTime now,
  }) {
    if (state == OccurrenceAdherenceState.inconsistent) {
      return TreatmentOccurrenceState.requiresReview;
    }
    if (row.status == RoutineOccurrenceStatus.canceled.name ||
        row.status == RoutineOccurrenceStatus.notApplicable.name ||
        row.status == RoutineOccurrenceStatus.paused.name) {
      return TreatmentOccurrenceState.canceled;
    }
    if (state == OccurrenceAdherenceState.missed) {
      return TreatmentOccurrenceState.missed;
    }
    if (state != OccurrenceAdherenceState.pending) {
      return TreatmentOccurrenceState.resolved;
    }
    if (now.isBefore(row.windowStartsAt)) {
      return TreatmentOccurrenceState.future;
    }
    if (now.isBefore(row.scheduledFor)) {
      return TreatmentOccurrenceState.due;
    }
    return TreatmentOccurrenceState.open;
  }

  Future<List<RoutineOccurrenceRecord>> _occurrences(
    DateTime start,
    DateTime end,
  ) =>
      (database.select(database.routineOccurrenceRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.originalClinicalDate.isBiggerOrEqualValue(_date(start)) &
                row.originalClinicalDate.isSmallerOrEqualValue(_date(end)) &
                row.deletedAt.isNull(),
          ))
          .get();

  Future<List<SmartRoutineRecord>> _routinesFor(
    Iterable<RoutineOccurrenceRecord> occurrences,
  ) async {
    final routineIds = occurrences.map((value) => value.routineId).toSet();
    if (routineIds.isEmpty) return const <SmartRoutineRecord>[];
    return (database.select(database.smartRoutineRecords)
          ..where((row) => row.userId.equals(userId) & row.id.isIn(routineIds)))
        .get();
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<Map<String, List<RoutineAdherenceEventRecord>>> _events(
    Iterable<String> occurrenceIds,
  ) async {
    final ids = occurrenceIds.toList();
    if (ids.isEmpty) return const {};
    final rows =
        await (database.select(database.routineAdherenceEventRecords)
              ..where(
                (row) => row.userId.equals(userId) & row.occurrenceId.isIn(ids),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.recordedAtUtc)]))
            .get();
    final result = <String, List<RoutineAdherenceEventRecord>>{};
    for (final row in rows) {
      result.putIfAbsent(row.occurrenceId, () => []).add(row);
    }
    return result;
  }

  RoutineOccurrence _occurrence(RoutineOccurrenceRecord row) =>
      RoutineOccurrence(
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

  RoutineAdherenceEvent _event(RoutineAdherenceEventRecord row) =>
      RoutineAdherenceEvent(
        eventId: RoutineAdherenceEventId(row.id),
        occurrenceId: RoutineOccurrenceId(row.occurrenceId),
        routineId: RoutineId(row.routineId),
        planId: RoutinePlanId(row.planId),
        scheduleId: row.scheduleId == null
            ? null
            : RoutineScheduleId(row.scheduleId!),
        type: AdherenceEventType.values.byName(row.type),
        actor: AdherenceEventActor.values.byName(row.actor),
        occurredAtUtc: row.occurredAtUtc.toUtc(),
        recordedAtUtc: row.recordedAtUtc.toUtc(),
        referencedEventId: row.referencedEventId == null
            ? null
            : RoutineAdherenceEventId(row.referencedEventId!),
        correctionAction: row.correctionAction == null
            ? null
            : AdherenceCorrectionAction.values.byName(row.correctionAction!),
        replacementType: row.replacementType == null
            ? null
            : AdherenceEventType.values.byName(row.replacementType!),
        replacementOccurredAtUtc: row.replacementOccurredAtUtc?.toUtc(),
        rescheduledWindow: row.rescheduledForUtc == null
            ? null
            : OccurrenceWindow(
                scheduledFor: row.rescheduledForUtc!.toUtc(),
                windowStartsAt: row.rescheduledWindowStartsAtUtc!.toUtc(),
                onTimeEndsAt: row.rescheduledOnTimeEndsAtUtc!.toUtc(),
                windowEndsAt: row.rescheduledWindowEndsAtUtc!.toUtc(),
              ),
        note: row.note,
        actualDose:
            row.actualDoseValue == null && row.actualDoseOriginalText == null
            ? null
            : DoseValue(
                value: row.actualDoseValue,
                unit: row.actualDoseUnit,
                originalText: row.actualDoseOriginalText,
              ),
      );
}

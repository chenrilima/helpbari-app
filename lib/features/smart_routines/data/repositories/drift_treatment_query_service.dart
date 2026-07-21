import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../domain/enums/routine_enums.dart';
import '../../domain/services/treatment_query_models.dart';
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
}

class DriftTreatmentAdherenceQueryService
    implements TreatmentAdherenceQueryService {
  const DriftTreatmentAdherenceQueryService({
    required this.database,
    required this.userId,
    this.minimumCoverage = .6,
  });
  final AppDatabase database;
  final String userId;
  final double minimumCoverage;

  @override
  Future<TreatmentAdherenceSummary> summary(
    DateTime start,
    DateTime end,
  ) async {
    final occurrences = await _occurrences(start, end);
    final events = await _events(occurrences.map((value) => value.id));
    var taken = 0;
    var onTime = 0;
    var skipped = 0;
    var missed = 0;
    final now = DateTime.now().toUtc();
    for (final occurrence in occurrences) {
      final terminal = events[occurrence.id]?.lastOrNull;
      if (terminal?.type == 'taken') {
        taken++;
        if (!terminal!.occurredAtUtc.isAfter(occurrence.onTimeEndsAt)) onTime++;
      } else if (terminal?.type == 'skipped') {
        skipped++;
      } else if (occurrence.windowEndsAt.isBefore(now)) {
        missed++;
      }
    }
    final eligible = taken + skipped + missed;
    final expected = occurrences.length;
    final coverage = expected == 0 ? 0.0 : eligible / expected;
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
    final start = DateTime(date.year, date.month, date.day);
    final occurrences = await _occurrences(start, start);
    final events = await _events(occurrences.map((value) => value.id));
    final routineIds = occurrences.map((value) => value.routineId).toSet();
    final routines = routineIds.isEmpty
        ? const <SmartRoutineRecord>[]
        : await (database.select(database.smartRoutineRecords)..where(
                (row) => row.userId.equals(userId) & row.id.isIn(routineIds),
              ))
              .get();
    final byId = {for (final row in routines) row.id: row};
    final items = occurrences.map((occurrence) {
      final terminal = events[occurrence.id]?.lastOrNull;
      final state = switch (terminal?.type) {
        'taken' =>
          terminal!.occurredAtUtc.isAfter(occurrence.onTimeEndsAt)
              ? OccurrenceAdherenceState.takenLate
              : OccurrenceAdherenceState.takenOnTime,
        'skipped' => OccurrenceAdherenceState.skipped,
        _ when occurrence.windowEndsAt.isBefore(DateTime.now().toUtc()) =>
          OccurrenceAdherenceState.missed,
        _ => OccurrenceAdherenceState.pending,
      };
      final routine = byId[occurrence.routineId];
      return TodayTreatmentOccurrence(
        id: occurrence.id,
        routineId: occurrence.routineId,
        category: RoutineCategory.values.byName(routine?.category ?? 'other'),
        title: routine?.displayName ?? 'Rotina',
        scheduledFor: occurrence.scheduledFor,
        windowEndsAt: occurrence.windowEndsAt,
        state: state,
      );
    }).toList()..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return TodayTreatmentReadModel(
      date: date,
      occurrences: List.unmodifiable(items),
      adherence: await summary(start, start),
    );
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
}

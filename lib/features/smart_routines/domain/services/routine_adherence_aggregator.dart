import 'dart:collection';

import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/typed_ids.dart';
import 'adherence_calculator.dart';
import 'routine_adherence_projector.dart';

final class RoutineAdherenceAggregate {
  RoutineAdherenceAggregate({
    required this.global,
    required Map<RoutineId, AdherenceCalculationResult> byRoutine,
    required Map<RoutineCategory, AdherenceCalculationResult> byCategory,
    required Map<RoutinePlanId, AdherenceCalculationResult> byPlan,
    required Map<RoutineScheduleId, AdherenceCalculationResult> bySchedule,
    required Map<String, AdherenceCalculationResult> byClinicalDay,
    required Iterable<AdherenceProjectionDiagnostic> diagnostics,
  }) : byRoutine = Map.unmodifiable(byRoutine),
       byCategory = Map.unmodifiable(byCategory),
       byPlan = Map.unmodifiable(byPlan),
       bySchedule = Map.unmodifiable(bySchedule),
       byClinicalDay = Map.unmodifiable(byClinicalDay),
       diagnostics = Set.unmodifiable(diagnostics);

  final AdherenceCalculationResult global;
  final Map<RoutineId, AdherenceCalculationResult> byRoutine;
  final Map<RoutineCategory, AdherenceCalculationResult> byCategory;
  final Map<RoutinePlanId, AdherenceCalculationResult> byPlan;
  final Map<RoutineScheduleId, AdherenceCalculationResult> bySchedule;
  final Map<String, AdherenceCalculationResult> byClinicalDay;
  final Set<AdherenceProjectionDiagnostic> diagnostics;
  UnmodifiableMapView<RoutineId, AdherenceCalculationResult>
  get immutableByRoutine => UnmodifiableMapView(byRoutine);
}

final class RoutineAdherenceAggregator {
  const RoutineAdherenceAggregator({
    this.projector = const RoutineAdherenceProjector(),
    this.calculator = const AdherenceCalculator(),
  });
  final RoutineAdherenceProjector projector;
  final AdherenceCalculator calculator;

  RoutineAdherenceAggregate aggregate({
    required Iterable<RoutineOccurrence> occurrences,
    required Iterable<RoutineAdherenceEvent> events,
    required DateTime startInclusiveUtc,
    required DateTime endExclusiveUtc,
    required DateTime evaluatedAtUtc,
    required Map<RoutineId, RoutineCategory> categoriesByRoutine,
    Iterable<RoutinePause> pauses = const [],
  }) {
    if (!startInclusiveUtc.isUtc ||
        !endExclusiveUtc.isUtc ||
        !evaluatedAtUtc.isUtc) {
      throw const SmartRoutineValidationException(
        'adherence_aggregate_requires_utc',
        'Aggregate boundaries and evaluation instant must be UTC.',
      );
    }
    if (endExclusiveUtc.isBefore(startInclusiveUtc)) {
      throw const SmartRoutineValidationException(
        'invalid_adherence_period',
        'The aggregate period is invalid.',
      );
    }
    final diagnostics = <AdherenceProjectionDiagnostic>{};
    final occurrenceById = <String, RoutineOccurrence>{};
    final occurrenceInput = occurrences.toList()
      ..sort((left, right) {
        final id = left.id.compareTo(right.id);
        if (id != 0) return id;
        final original = left.originalScheduledFor.compareTo(
          right.originalScheduledFor,
        );
        if (original != 0) return original;
        final current = left.currentScheduledFor.compareTo(
          right.currentScheduledFor,
        );
        return current != 0
            ? current
            : left.planId.value.compareTo(right.planId.value);
      });
    for (final occurrence in occurrenceInput) {
      if (occurrenceById.containsKey(occurrence.id)) {
        diagnostics.add(AdherenceProjectionDiagnostic.duplicateOccurrence);
      } else {
        occurrenceById[occurrence.id] = occurrence;
      }
    }
    final eventInput = events.toList();
    final pauseInput = pauses.toList();
    final selected =
        occurrenceById.values
            .where(
              (occurrence) =>
                  !occurrence.originalScheduledFor.isBefore(
                    startInclusiveUtc,
                  ) &&
                  occurrence.originalScheduledFor.isBefore(endExclusiveUtc),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.originalScheduledFor.compareTo(right.originalScheduledFor),
          );
    final projections = <_OccurrenceProjection>[];
    for (final occurrence in selected) {
      final projection = projector.project(
        occurrence: occurrence,
        events: eventInput.where(
          (event) => event.occurrenceId == occurrence.occurrenceId,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
        pauses: pauseInput,
      );
      diagnostics.addAll(projection.diagnostics);
      final category = categoriesByRoutine[occurrence.routineId];
      if (category == null) {
        diagnostics.add(AdherenceProjectionDiagnostic.missingCategory);
      }
      projections.add(_OccurrenceProjection(occurrence, projection, category));
    }
    return RoutineAdherenceAggregate(
      global: calculator.calculate(projections.map((item) => item.projection)),
      byRoutine: _group(projections, (item) => item.occurrence.routineId),
      byCategory: _group(
        projections.where((item) => item.category != null),
        (item) => item.category!,
      ),
      byPlan: _group(projections, (item) => item.occurrence.planId),
      bySchedule: _group(
        projections.where((item) => item.occurrence.scheduleId != null),
        (item) => item.occurrence.scheduleId!,
      ),
      byClinicalDay: _group(
        projections,
        (item) => item.occurrence.originalClinicalDate.toString(),
      ),
      diagnostics: diagnostics,
    );
  }

  Map<K, AdherenceCalculationResult> _group<K>(
    Iterable<_OccurrenceProjection> values,
    K Function(_OccurrenceProjection value) keyOf,
  ) {
    final groups = <K, List<RoutineAdherenceProjection>>{};
    for (final value in values) {
      groups.putIfAbsent(keyOf(value), () => []).add(value.projection);
    }
    return {
      for (final entry in groups.entries)
        entry.key: calculator.calculate(entry.value),
    };
  }
}

final class _OccurrenceProjection {
  const _OccurrenceProjection(this.occurrence, this.projection, this.category);
  final RoutineOccurrence occurrence;
  final RoutineAdherenceProjection projection;
  final RoutineCategory? category;
}

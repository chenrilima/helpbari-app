import 'dart:collection';

import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../value_objects/local_date.dart';
import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/typed_ids.dart';
import 'occurrence_blueprint_generation_result.dart';
import 'occurrence_blueprint_generator.dart';
import 'occurrence_blueprint_range_generator.dart';
import 'routine_occurrence_materializer.dart';
import 'schedule_instant_resolver.dart';

enum RoutineOccurrenceGenerationStatus {
  generated,
  noBlueprints,
  partialGeneration,
  failed,
}

final class RoutineOccurrenceGenerationResult {
  RoutineOccurrenceGenerationResult({
    required this.status,
    required Iterable<RoutineOccurrence> occurrences,
    required Iterable<OccurrenceMaterializationResult> failures,
    required this.blueprintResult,
  }) : occurrences = List.unmodifiable(occurrences),
       failures = List.unmodifiable(failures);

  final RoutineOccurrenceGenerationStatus status;
  final List<RoutineOccurrence> occurrences;
  final List<OccurrenceMaterializationResult> failures;
  final OccurrenceBlueprintGenerationResult? blueprintResult;
  UnmodifiableListView<RoutineOccurrence> get immutableOccurrences =>
      UnmodifiableListView(occurrences);
}

final class RoutineOccurrenceGenerator {
  const RoutineOccurrenceGenerator({
    this.blueprintGenerator = const OccurrenceBlueprintGenerator(),
    this.materializer = const RoutineOccurrenceMaterializer(),
  });

  final OccurrenceBlueprintGenerator blueprintGenerator;
  final RoutineOccurrenceMaterializer materializer;

  RoutineOccurrenceGenerationResult generate({
    required SmartRoutine routine,
    required Iterable<RoutinePlan> plans,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutinePause> pauses,
    required LocalDate clinicalDate,
    required DateTime operationalAt,
    NonexistentLocalTimePolicy nonexistentPolicy =
        NonexistentLocalTimePolicy.shiftForward,
    AmbiguousLocalTimePolicy ambiguousPolicy =
        AmbiguousLocalTimePolicy.earlierOccurrence,
  }) {
    if (!operationalAt.isUtc) {
      throw ArgumentError.value(
        operationalAt,
        'operationalAt',
        'A UTC instant is required.',
      );
    }
    final scheduleInput = schedules.toList();
    final blueprintResult = blueprintGenerator.generate(
      routine: routine,
      plans: plans.toList(),
      schedules: scheduleInput,
      pauses: pauses.toList(),
      clinicalDate: clinicalDate,
      operationalAt: operationalAt,
    );
    return materializeBlueprints(
      blueprints: blueprintResult.blueprints,
      schedules: scheduleInput,
      blueprintResult: blueprintResult,
      nonexistentPolicy: nonexistentPolicy,
      ambiguousPolicy: ambiguousPolicy,
    );
  }

  RoutineOccurrenceGenerationResult materializeBlueprints({
    required Iterable<OccurrenceBlueprint> blueprints,
    required Iterable<RoutineSchedule> schedules,
    OccurrenceBlueprintGenerationResult? blueprintResult,
    NonexistentLocalTimePolicy nonexistentPolicy =
        NonexistentLocalTimePolicy.shiftForward,
    AmbiguousLocalTimePolicy ambiguousPolicy =
        AmbiguousLocalTimePolicy.earlierOccurrence,
  }) {
    final scheduleById = <RoutineScheduleId, RoutineSchedule>{
      for (final schedule in schedules) schedule.scheduleId: schedule,
    };
    final resolved =
        <({OccurrenceBlueprint blueprint, ResolvedLocalScheduleTime value})>[];
    final failures = <OccurrenceMaterializationResult>[];
    for (final blueprint in blueprints) {
      final temporal = materializer.instantResolver.resolve(
        localDate: blueprint.clinicalDate,
        localTime: blueprint.localTime,
        timeZone: blueprint.timeZone,
        nonexistentPolicy: nonexistentPolicy,
        ambiguousPolicy: ambiguousPolicy,
      );
      if (!temporal.isResolved) {
        failures.add(
          OccurrenceMaterializationResult.failed(
            failure: OccurrenceMaterializationFailure.temporalResolution,
            temporalFailure: temporal.failure,
          ),
        );
      } else {
        resolved.add((blueprint: blueprint, value: temporal.value!));
      }
    }
    resolved.sort((left, right) {
      final instant = left.value.instantUtc.compareTo(right.value.instantUtc);
      return instant != 0 ? instant : left.blueprint.compareTo(right.blueprint);
    });
    final byId = <RoutineOccurrenceId, RoutineOccurrence>{};
    for (var index = 0; index < resolved.length; index++) {
      final item = resolved[index];
      final schedule = scheduleById[item.blueprint.scheduleId];
      final result = materializer.materialize(
        blueprint: item.blueprint,
        windowDefinition: schedule?.windowDefinition,
        preResolved: item.value,
        nextTargetAtUtc: _nextDistinctInstant(resolved, index),
      );
      if (result.isMaterialized) {
        byId.putIfAbsent(
          result.occurrence!.occurrenceId,
          () => result.occurrence!,
        );
      } else {
        failures.add(result);
      }
    }
    final occurrences = byId.values.toList()..sort(_compareOccurrences);
    final status = occurrences.isEmpty
        ? failures.isEmpty
              ? RoutineOccurrenceGenerationStatus.noBlueprints
              : RoutineOccurrenceGenerationStatus.failed
        : failures.isEmpty
        ? RoutineOccurrenceGenerationStatus.generated
        : RoutineOccurrenceGenerationStatus.partialGeneration;
    return RoutineOccurrenceGenerationResult(
      status: status,
      occurrences: occurrences,
      failures: failures,
      blueprintResult: blueprintResult,
    );
  }

  DateTime? _nextDistinctInstant(
    List<({OccurrenceBlueprint blueprint, ResolvedLocalScheduleTime value})>
    resolved,
    int index,
  ) {
    final current = resolved[index].value.instantUtc;
    for (var next = index + 1; next < resolved.length; next++) {
      final candidate = resolved[next].value.instantUtc;
      if (candidate.isAfter(current)) return candidate;
    }
    return null;
  }

  int _compareOccurrences(RoutineOccurrence left, RoutineOccurrence right) {
    final original = left.originalScheduledFor.compareTo(
      right.originalScheduledFor,
    );
    if (original != 0) return original;
    final current = left.currentScheduledFor.compareTo(
      right.currentScheduledFor,
    );
    if (current != 0) return current;
    final schedule = left.scheduleId!.value.compareTo(right.scheduleId!.value);
    if (schedule != 0) return schedule;
    final sequence = left.sequence.compareTo(right.sequence);
    return sequence != 0
        ? sequence
        : left.occurrenceId.value.compareTo(right.occurrenceId.value);
  }
}

final class RoutineOccurrenceRangeGenerator {
  const RoutineOccurrenceRangeGenerator({
    this.blueprintRangeGenerator = const OccurrenceBlueprintRangeGenerator(),
    this.occurrenceGenerator = const RoutineOccurrenceGenerator(),
  });
  final OccurrenceBlueprintRangeGenerator blueprintRangeGenerator;
  final RoutineOccurrenceGenerator occurrenceGenerator;

  RoutineOccurrenceGenerationResult generate({
    required SmartRoutine routine,
    required Iterable<RoutinePlan> plans,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutinePause> pauses,
    required LocalDate startDate,
    required LocalDate endDateExclusive,
    required int maxDays,
    required OperationalInstantForDate operationalInstantForDate,
  }) {
    final scheduleInput = schedules.toList();
    final range = blueprintRangeGenerator.generate(
      routine: routine,
      plans: plans.toList(),
      schedules: scheduleInput,
      pauses: pauses.toList(),
      startDate: startDate,
      endDateExclusive: endDateExclusive,
      maxDays: maxDays,
      operationalInstantForDate: operationalInstantForDate,
    );
    return occurrenceGenerator.materializeBlueprints(
      blueprints: range.blueprints,
      schedules: scheduleInput,
    );
  }
}

import '../entities/entities.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/local_date.dart';
import '../value_objects/occurrence_blueprint.dart';
import 'occurrence_blueprint_generation_result.dart';
import 'occurrence_blueprint_generator.dart';

typedef OperationalInstantForDate = DateTime Function(LocalDate clinicalDate);

/// Generates the semi-open clinical interval [startDate, endDateExclusive).
final class OccurrenceBlueprintRangeGenerator {
  const OccurrenceBlueprintRangeGenerator({
    this.dailyGenerator = const OccurrenceBlueprintGenerator(),
  });

  final OccurrenceBlueprintGenerator dailyGenerator;

  OccurrenceBlueprintRangeResult generate({
    required SmartRoutine routine,
    required Iterable<RoutinePlan> plans,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutinePause> pauses,
    required LocalDate startDate,
    required LocalDate endDateExclusive,
    required int maxDays,
    required OperationalInstantForDate operationalInstantForDate,
  }) {
    if (maxDays <= 0) {
      throw const SmartRoutineValidationException(
        'invalid_blueprint_range_limit',
        'Blueprint range maxDays must be positive.',
      );
    }
    final comparison = startDate.compareTo(endDateExclusive);
    if (comparison > 0) {
      return OccurrenceBlueprintRangeResult(
        status: OccurrenceBlueprintRangeStatus.invalidRange,
        blueprints: const [],
        dailyResults: const [],
      );
    }
    if (comparison == 0) {
      return OccurrenceBlueprintRangeResult(
        status: OccurrenceBlueprintRangeStatus.emptyRange,
        blueprints: const [],
        dailyResults: const [],
      );
    }
    final days = endDateExclusive.daysSince(startDate);
    if (days > maxDays) {
      return OccurrenceBlueprintRangeResult(
        status: OccurrenceBlueprintRangeStatus.maxDaysExceeded,
        blueprints: const [],
        dailyResults: const [],
      );
    }

    final planInput = plans.toList();
    final scheduleInput = schedules.toList();
    final pauseInput = pauses.toList();
    final dailyResults = <OccurrenceBlueprintGenerationResult>[];
    final byKey = <OccurrenceBlueprintLogicalKey, OccurrenceBlueprint>{};
    for (var offset = 0; offset < days; offset++) {
      final date = startDate.addDays(offset);
      final result = dailyGenerator.generate(
        routine: routine,
        plans: planInput,
        schedules: scheduleInput,
        pauses: pauseInput,
        clinicalDate: date,
        operationalAt: operationalInstantForDate(date),
      );
      dailyResults.add(result);
      for (final blueprint in result.blueprints) {
        byKey.putIfAbsent(blueprint.logicalKey, () => blueprint);
      }
    }
    final blueprints = byKey.values.toList()..sort();
    return OccurrenceBlueprintRangeResult(
      status: blueprints.isEmpty
          ? OccurrenceBlueprintRangeStatus.noBlueprints
          : OccurrenceBlueprintRangeStatus.generated,
      blueprints: blueprints,
      dailyResults: dailyResults,
    );
  }
}

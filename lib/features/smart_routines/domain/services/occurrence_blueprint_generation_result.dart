import '../entities/entities.dart';
import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/typed_ids.dart';

enum OccurrenceBlueprintGenerationStatus {
  generated,
  noValidPlan,
  multipleValidPlans,
  routineIneligible,
  noSchedules,
  noEligibleSchedules,
  paused,
  asNeededOnly,
  unstructuredOnly,
  requiresInstantEvaluation,
  unsupportedRule,
  inconsistentData,
}

enum OccurrenceBlueprintGenerationIssue {
  duplicateRevision,
  foreignRoutine,
  inconsistentPlanChain,
  orphanSchedule,
  incompatibleSchedule,
  overlappingPauses,
}

final class OccurrenceBlueprintGenerationResult {
  OccurrenceBlueprintGenerationResult({
    required this.status,
    required Iterable<OccurrenceBlueprint> blueprints,
    required Iterable<RoutineScheduleId> evaluatedScheduleIds,
    required Iterable<RoutineScheduleId> ignoredScheduleIds,
    required Iterable<OccurrenceBlueprintGenerationIssue> issues,
    this.selectedPlan,
  }) : blueprints = List.unmodifiable(blueprints),
       evaluatedScheduleIds = List.unmodifiable(evaluatedScheduleIds),
       ignoredScheduleIds = List.unmodifiable(ignoredScheduleIds),
       issues = List.unmodifiable(issues);

  final OccurrenceBlueprintGenerationStatus status;
  final List<OccurrenceBlueprint> blueprints;
  final RoutinePlan? selectedPlan;
  final List<RoutineScheduleId> evaluatedScheduleIds;
  final List<RoutineScheduleId> ignoredScheduleIds;
  final List<OccurrenceBlueprintGenerationIssue> issues;

  bool get hasBlueprints => blueprints.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceBlueprintGenerationResult &&
      status == other.status &&
      selectedPlan == other.selectedPlan &&
      _listEquals(blueprints, other.blueprints) &&
      _listEquals(evaluatedScheduleIds, other.evaluatedScheduleIds) &&
      _listEquals(ignoredScheduleIds, other.ignoredScheduleIds) &&
      _listEquals(issues, other.issues);

  @override
  int get hashCode => Object.hash(
    status,
    selectedPlan,
    Object.hashAll(blueprints),
    Object.hashAll(evaluatedScheduleIds),
    Object.hashAll(ignoredScheduleIds),
    Object.hashAll(issues),
  );
}

enum OccurrenceBlueprintRangeStatus {
  generated,
  noBlueprints,
  emptyRange,
  invalidRange,
  maxDaysExceeded,
}

final class OccurrenceBlueprintRangeResult {
  OccurrenceBlueprintRangeResult({
    required this.status,
    required Iterable<OccurrenceBlueprint> blueprints,
    required Iterable<OccurrenceBlueprintGenerationResult> dailyResults,
  }) : blueprints = List.unmodifiable(blueprints),
       dailyResults = List.unmodifiable(dailyResults);

  final OccurrenceBlueprintRangeStatus status;
  final List<OccurrenceBlueprint> blueprints;
  final List<OccurrenceBlueprintGenerationResult> dailyResults;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceBlueprintRangeResult &&
      status == other.status &&
      _listEquals(blueprints, other.blueprints) &&
      _listEquals(dailyResults, other.dailyResults);

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAll(blueprints),
    Object.hashAll(dailyResults),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

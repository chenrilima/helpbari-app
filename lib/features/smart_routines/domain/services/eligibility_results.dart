import 'dart:collection';

import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../value_objects/routine_values.dart';

enum PlanValidityReason {
  valid,
  notActivated,
  planNotStarted,
  planExpired,
  planReplaced,
}

final class PlanValidityResult {
  const PlanValidityResult(this.reason);
  final PlanValidityReason reason;
  bool get isValid => reason == PlanValidityReason.valid;
  @override
  bool operator ==(Object other) =>
      other is PlanValidityResult && reason == other.reason;
  @override
  int get hashCode => reason.hashCode;
}

enum PlanSelectionReason {
  selected,
  noValidPlan,
  multipleValidPlans,
  duplicateRevision,
  foreignRoutine,
  inconsistentChain,
}

final class PlanSelectionResult {
  PlanSelectionResult({
    required this.reason,
    this.selectedPlan,
    Iterable<RoutinePlan> conflictingPlans = const [],
  }) : conflictingPlans = List.unmodifiable(conflictingPlans);

  final PlanSelectionReason reason;
  final RoutinePlan? selectedPlan;
  final List<RoutinePlan> conflictingPlans;
  bool get isSelected => reason == PlanSelectionReason.selected;

  @override
  bool operator ==(Object other) =>
      other is PlanSelectionResult &&
      reason == other.reason &&
      selectedPlan == other.selectedPlan &&
      _listEquals(conflictingPlans, other.conflictingPlans);
  @override
  int get hashCode =>
      Object.hash(reason, selectedPlan, Object.hashAll(conflictingPlans));
}

enum ScheduleCompatibilityReason {
  compatible,
  planIdMismatch,
  scheduledPlanWithAsNeededRule,
  asNeededPlanWithScheduledRule,
}

final class ScheduleCompatibilityResult {
  const ScheduleCompatibilityResult(this.reason);
  final ScheduleCompatibilityReason reason;
  bool get isCompatible => reason == ScheduleCompatibilityReason.compatible;
  @override
  bool operator ==(Object other) =>
      other is ScheduleCompatibilityResult && reason == other.reason;
  @override
  int get hashCode => reason.hashCode;
}

final class PauseEvaluationResult {
  PauseEvaluationResult({
    required Iterable<RoutinePause> applicablePauses,
    required this.hasOverlap,
  }) : applicablePauses = List.unmodifiable(applicablePauses);

  final List<RoutinePause> applicablePauses;
  final bool hasOverlap;
  bool get isPaused => applicablePauses.isNotEmpty;
  UnmodifiableListView<RoutinePause> get pauses =>
      UnmodifiableListView(applicablePauses);

  @override
  bool operator ==(Object other) =>
      other is PauseEvaluationResult &&
      hasOverlap == other.hasOverlap &&
      _listEquals(applicablePauses, other.applicablePauses);
  @override
  int get hashCode => Object.hash(hasOverlap, Object.hashAll(applicablePauses));
}

enum ScheduleDateEligibilityReason {
  eligible,
  notEligible,
  requiresInstantEvaluation,
  asNeeded,
  unstructured,
  unsupported,
}

final class ScheduleDateEligibilityResult {
  const ScheduleDateEligibilityResult({
    required this.reason,
    required this.expectationKind,
  });
  final ScheduleDateEligibilityReason reason;
  final ExpectationKind expectationKind;
  bool get isEligible => reason == ScheduleDateEligibilityReason.eligible;
  @override
  bool operator ==(Object other) =>
      other is ScheduleDateEligibilityResult &&
      reason == other.reason &&
      expectationKind == other.expectationKind;
  @override
  int get hashCode => Object.hash(reason, expectationKind);
}

enum ScheduleTimesResolutionReason {
  resolved,
  dateNotEligible,
  requiresInstantEvaluation,
  asNeeded,
  unstructured,
  unsupported,
}

final class ScheduleTimesResolution {
  ScheduleTimesResolution({
    required Iterable<TimeOfDayValue> times,
    required this.reason,
    required this.expectationKind,
  }) : times = List.unmodifiable(times);
  final List<TimeOfDayValue> times;
  final ScheduleTimesResolutionReason reason;
  final ExpectationKind expectationKind;
  @override
  bool operator ==(Object other) =>
      other is ScheduleTimesResolution &&
      reason == other.reason &&
      expectationKind == other.expectationKind &&
      _listEquals(times, other.times);
  @override
  int get hashCode =>
      Object.hash(reason, expectationKind, Object.hashAll(times));
}

enum PlanScheduleSelectionReason {
  selected,
  selectedWithOrphans,
  noSelectedPlan,
}

final class PlanScheduleSelectionResult {
  PlanScheduleSelectionResult({
    required this.reason,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutineSchedule> orphanSchedules,
  }) : schedules = List.unmodifiable(schedules),
       orphanSchedules = List.unmodifiable(orphanSchedules);
  final PlanScheduleSelectionReason reason;
  final List<RoutineSchedule> schedules;
  final List<RoutineSchedule> orphanSchedules;
  @override
  bool operator ==(Object other) =>
      other is PlanScheduleSelectionResult &&
      reason == other.reason &&
      _listEquals(schedules, other.schedules) &&
      _listEquals(orphanSchedules, other.orphanSchedules);
  @override
  int get hashCode => Object.hash(
    reason,
    Object.hashAll(schedules),
    Object.hashAll(orphanSchedules),
  );
}

enum RoutineEligibilityReason {
  eligible,
  routineInactive,
  routinePaused,
  routineCompleted,
  routineCanceled,
  routineArchived,
  routineDeleted,
  planNotStarted,
  planExpired,
  planNotActivated,
  planReplaced,
  scheduleDisabled,
  scheduleIncompatible,
  paused,
  asNeeded,
  unsupportedRule,
  dateNotEligible,
}

final class RoutineEligibilityResult {
  const RoutineEligibilityResult(this.reason);
  final RoutineEligibilityReason reason;
  bool get isEligible => reason == RoutineEligibilityReason.eligible;
  @override
  bool operator ==(Object other) =>
      other is RoutineEligibilityResult && reason == other.reason;
  @override
  int get hashCode => reason.hashCode;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

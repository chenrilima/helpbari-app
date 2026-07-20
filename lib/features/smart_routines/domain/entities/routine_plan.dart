import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/local_date.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/schedule_rule.dart';
import '../value_objects/typed_ids.dart';

/// The two immutable snapshots produced by a plan revision.
///
/// Persistence must store [previousPlan] and [newPlan] atomically. This domain
/// result performs no persistence and mutates neither source nor result plans.
final class PlanRevisionResult {
  const PlanRevisionResult({required this.previousPlan, required this.newPlan});

  final RoutinePlan previousPlan;
  final RoutinePlan newPlan;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanRevisionResult &&
          previousPlan == other.previousPlan &&
          newPlan == other.newPlan;

  @override
  int get hashCode => Object.hash(previousPlan, newPlan);
}

final class RoutinePlan extends Entity {
  factory RoutinePlan({
    required RoutinePlanId planId,
    required RoutineId routineId,
    required int revision,
    required RoutinePlanMode mode,
    required PlanDurationType durationType,
    required LocalDate effectiveFrom,
    required DateTime createdAt,
    DoseValue? dose,
    String? route,
    String? clinicalInstructions,
    LocalDate? effectiveUntil,
    DateTime? activatedAt,
    DateTime? replacedAt,
    RoutinePlanId? previousPlanId,
  }) {
    if (revision < 1) {
      throw const SmartRoutineValidationException(
        'invalid_plan_revision',
        'Plan revision must be at least 1.',
      );
    }
    if (effectiveUntil != null && effectiveUntil.compareTo(effectiveFrom) < 0) {
      throw const SmartRoutineValidationException(
        'invalid_plan_effective_period',
        'Plan end cannot precede its start.',
      );
    }
    if (durationType == PlanDurationType.fixed && effectiveUntil == null) {
      throw const SmartRoutineValidationException(
        'fixed_plan_end_required',
        'Fixed duration requires effectiveUntil.',
      );
    }
    if (durationType != PlanDurationType.fixed && effectiveUntil != null) {
      throw const SmartRoutineValidationException(
        'unexpected_plan_end',
        'Continuous and unknown duration plans cannot imply a fixed end.',
      );
    }
    if (activatedAt != null && activatedAt.isBefore(createdAt)) {
      throw const SmartRoutineValidationException(
        'invalid_plan_activation',
        'Plan activation cannot precede creation.',
      );
    }
    if (replacedAt != null && activatedAt == null) {
      throw const SmartRoutineValidationException(
        'inactive_plan_replacement',
        'Only an activated plan can be replaced.',
      );
    }
    if (replacedAt != null && replacedAt.isBefore(activatedAt!)) {
      throw const SmartRoutineValidationException(
        'invalid_plan_replacement',
        'Plan replacement cannot precede activation.',
      );
    }
    return RoutinePlan._(
      planId: planId,
      routineId: routineId,
      revision: revision,
      mode: mode,
      durationType: durationType,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      dose: dose,
      route: _optional(route),
      clinicalInstructions: _optional(clinicalInstructions),
      createdAt: createdAt,
      activatedAt: activatedAt,
      replacedAt: replacedAt,
      previousPlanId: previousPlanId,
    );
  }

  const RoutinePlan._({
    required this.planId,
    required this.routineId,
    required this.revision,
    required this.mode,
    required this.durationType,
    required this.effectiveFrom,
    required this.createdAt,
    this.effectiveUntil,
    this.dose,
    this.route,
    this.clinicalInstructions,
    this.activatedAt,
    this.replacedAt,
    this.previousPlanId,
  });

  final RoutinePlanId planId;
  @override
  String get id => planId.value;
  final RoutineId routineId;
  final int revision;
  final RoutinePlanMode mode;
  final PlanDurationType durationType;
  final LocalDate effectiveFrom;
  final LocalDate? effectiveUntil;
  final DoseValue? dose;
  final String? route;
  final String? clinicalInstructions;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? replacedAt;
  final RoutinePlanId? previousPlanId;

  bool acceptsRule(ScheduleRule rule) => switch (mode) {
    RoutinePlanMode.asNeeded => rule is AsNeededRule,
    RoutinePlanMode.scheduled => rule is! AsNeededRule,
  };

  void ensureCompatibleRule(ScheduleRule rule) {
    if (!acceptsRule(rule)) {
      throw const SmartRoutineValidationException(
        'incompatible_plan_schedule',
        'Plan mode and schedule rule are incompatible.',
      );
    }
  }

  PlanRevisionResult createRevision({
    required RoutinePlanId newPlanId,
    required DateTime at,
    required LocalDate effectiveFrom,
    RoutinePlanMode? mode,
    PlanDurationType? durationType,
    LocalDate? effectiveUntil,
    DoseValue? dose,
    String? route,
    String? clinicalInstructions,
  }) {
    if (activatedAt == null || replacedAt != null) {
      throw const SmartRoutineValidationException(
        'plan_not_revisionable',
        'Only an active unreplaced plan can create a revision.',
      );
    }
    if (newPlanId == planId) {
      throw const SmartRoutineValidationException(
        'duplicate_plan_revision_id',
        'A plan revision requires a new identity.',
      );
    }
    final replaced = RoutinePlan(
      planId: planId,
      routineId: routineId,
      revision: revision,
      mode: this.mode,
      durationType: this.durationType,
      effectiveFrom: this.effectiveFrom,
      effectiveUntil: this.effectiveUntil,
      dose: this.dose,
      route: this.route,
      clinicalInstructions: this.clinicalInstructions,
      createdAt: createdAt,
      activatedAt: activatedAt,
      replacedAt: at,
      previousPlanId: previousPlanId,
    );
    final nextDuration = durationType ?? this.durationType;
    final next = RoutinePlan(
      planId: newPlanId,
      routineId: routineId,
      revision: revision + 1,
      mode: mode ?? this.mode,
      durationType: nextDuration,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      dose: dose ?? this.dose,
      route: route ?? this.route,
      clinicalInstructions: clinicalInstructions ?? this.clinicalInstructions,
      createdAt: at,
      previousPlanId: planId,
    );
    return PlanRevisionResult(previousPlan: replaced, newPlan: next);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutinePlan &&
          planId == other.planId &&
          routineId == other.routineId &&
          revision == other.revision &&
          mode == other.mode &&
          durationType == other.durationType &&
          effectiveFrom == other.effectiveFrom &&
          effectiveUntil == other.effectiveUntil &&
          dose == other.dose &&
          route == other.route &&
          clinicalInstructions == other.clinicalInstructions &&
          createdAt == other.createdAt &&
          activatedAt == other.activatedAt &&
          replacedAt == other.replacedAt &&
          previousPlanId == other.previousPlanId;

  @override
  int get hashCode => Object.hash(
    planId,
    routineId,
    revision,
    mode,
    durationType,
    effectiveFrom,
    effectiveUntil,
    dose,
    route,
    clinicalInstructions,
    createdAt,
    activatedAt,
    replacedAt,
    previousPlanId,
  );
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

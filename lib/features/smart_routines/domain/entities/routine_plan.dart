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
    RoutineCategory category = RoutineCategory.other,
    required LocalDate effectiveFrom,
    required DateTime createdAt,
    DoseValue? dose,
    String? route,
    String? clinicalInstructions,
    LocalDate? effectiveUntil,
    DateTime? activatedAt,
    DateTime? replacedAt,
    RoutinePlanId? previousPlanId,
    RoutinePlanProvenance provenance = const RoutinePlanProvenance.manual(),
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
    if (durationType == PlanDurationType.bounded && effectiveUntil == null) {
      throw const SmartRoutineValidationException(
        'fixed_plan_end_required',
        'Fixed duration requires effectiveUntil.',
      );
    }
    if (durationType != PlanDurationType.bounded && effectiveUntil != null) {
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
      category: category,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      dose: dose,
      route: _optional(route),
      clinicalInstructions: _optional(clinicalInstructions),
      createdAt: createdAt,
      activatedAt: activatedAt,
      replacedAt: replacedAt,
      previousPlanId: previousPlanId,
      provenance: provenance,
    );
  }

  const RoutinePlan._({
    required this.planId,
    required this.routineId,
    required this.revision,
    required this.mode,
    required this.durationType,
    required this.category,
    required this.effectiveFrom,
    required this.createdAt,
    this.effectiveUntil,
    this.dose,
    this.route,
    this.clinicalInstructions,
    this.activatedAt,
    this.replacedAt,
    this.previousPlanId,
    this.provenance = const RoutinePlanProvenance.manual(),
  });

  final RoutinePlanId planId;
  @override
  String get id => planId.value;
  final RoutineId routineId;
  final int revision;
  final RoutinePlanMode mode;
  final PlanDurationType durationType;
  final RoutineCategory category;
  final LocalDate effectiveFrom;
  final LocalDate? effectiveUntil;
  final DoseValue? dose;
  final String? route;
  final String? clinicalInstructions;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? replacedAt;
  final RoutinePlanId? previousPlanId;
  final RoutinePlanProvenance provenance;

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
    RoutineCategory? category,
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
      category: this.category,
      effectiveFrom: this.effectiveFrom,
      effectiveUntil: this.effectiveUntil,
      dose: this.dose,
      route: this.route,
      clinicalInstructions: this.clinicalInstructions,
      createdAt: createdAt,
      activatedAt: activatedAt,
      replacedAt: at,
      previousPlanId: previousPlanId,
      provenance: provenance,
    );
    final nextDuration = durationType ?? this.durationType;
    final next = RoutinePlan(
      planId: newPlanId,
      routineId: routineId,
      revision: revision + 1,
      mode: mode ?? this.mode,
      durationType: nextDuration,
      category: category ?? this.category,
      effectiveFrom: effectiveFrom,
      effectiveUntil: effectiveUntil,
      dose: dose ?? this.dose,
      route: route ?? this.route,
      clinicalInstructions: clinicalInstructions ?? this.clinicalInstructions,
      createdAt: at,
      previousPlanId: planId,
      provenance: provenance,
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
          category == other.category &&
          effectiveFrom == other.effectiveFrom &&
          effectiveUntil == other.effectiveUntil &&
          dose == other.dose &&
          route == other.route &&
          clinicalInstructions == other.clinicalInstructions &&
          createdAt == other.createdAt &&
          activatedAt == other.activatedAt &&
          replacedAt == other.replacedAt &&
          previousPlanId == other.previousPlanId &&
          provenance == other.provenance;

  @override
  int get hashCode => Object.hash(
    planId,
    routineId,
    revision,
    mode,
    durationType,
    category,
    effectiveFrom,
    effectiveUntil,
    dose,
    route,
    clinicalInstructions,
    createdAt,
    activatedAt,
    replacedAt,
    previousPlanId,
    provenance,
  );
}

final class RoutinePlanProvenance {
  const RoutinePlanProvenance({
    required this.origin,
    required this.validationStatus,
    this.prescriptionId,
    this.prescriptionItemId,
    this.documentId,
    this.professionalReference,
    this.temporalPrecision = RoutineTemporalPrecision.exact,
  });

  const RoutinePlanProvenance.manual()
    : origin = RoutinePlanOrigin.manual,
      validationStatus = RoutineValidationStatus.confirmed,
      prescriptionId = null,
      prescriptionItemId = null,
      documentId = null,
      professionalReference = null,
      temporalPrecision = RoutineTemporalPrecision.exact;

  final RoutinePlanOrigin origin;
  final RoutineValidationStatus validationStatus;
  final String? prescriptionId;
  final String? prescriptionItemId;
  final String? documentId;
  final String? professionalReference;
  final RoutineTemporalPrecision temporalPrecision;

  @override
  bool operator ==(Object other) =>
      other is RoutinePlanProvenance &&
      origin == other.origin &&
      validationStatus == other.validationStatus &&
      prescriptionId == other.prescriptionId &&
      prescriptionItemId == other.prescriptionItemId &&
      documentId == other.documentId &&
      professionalReference == other.professionalReference &&
      temporalPrecision == other.temporalPrecision;

  @override
  int get hashCode => Object.hash(
    origin,
    validationStatus,
    prescriptionId,
    prescriptionItemId,
    documentId,
    professionalReference,
    temporalPrecision,
  );
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

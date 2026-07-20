import '../entities/routine_occurrence.dart';
import '../enums/routine_enums.dart';
import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/routine_values.dart';
import 'occurrence_window_resolver.dart';
import 'routine_occurrence_identity_generator.dart';
import 'schedule_instant_resolver.dart';

final class OccurrenceMaterializationResult {
  const OccurrenceMaterializationResult._({
    this.occurrence,
    this.resolution,
    this.failure,
    this.temporalFailure,
  });

  const OccurrenceMaterializationResult.materialized({
    required RoutineOccurrence occurrence,
    required ResolvedLocalScheduleTime resolution,
  }) : this._(occurrence: occurrence, resolution: resolution);

  const OccurrenceMaterializationResult.failed({
    required OccurrenceMaterializationFailure failure,
    ScheduleInstantResolutionFailure? temporalFailure,
  }) : this._(failure: failure, temporalFailure: temporalFailure);

  final RoutineOccurrence? occurrence;
  final ResolvedLocalScheduleTime? resolution;
  final OccurrenceMaterializationFailure? failure;
  final ScheduleInstantResolutionFailure? temporalFailure;
  bool get isMaterialized => occurrence != null;
}

final class RoutineOccurrenceMaterializer {
  const RoutineOccurrenceMaterializer({
    this.instantResolver = const ScheduleInstantResolver(),
    this.identityGenerator = const RoutineOccurrenceIdentityGenerator(),
    this.windowResolver = const OccurrenceWindowResolver(),
  });

  final ScheduleInstantResolver instantResolver;
  final RoutineOccurrenceIdentityGenerator identityGenerator;
  final OccurrenceWindowResolver windowResolver;

  OccurrenceMaterializationResult materialize({
    required OccurrenceBlueprint blueprint,
    required OccurrenceWindowDefinition? windowDefinition,
    DateTime? nextTargetAtUtc,
    ResolvedLocalScheduleTime? preResolved,
    NonexistentLocalTimePolicy nonexistentPolicy =
        NonexistentLocalTimePolicy.shiftForward,
    AmbiguousLocalTimePolicy ambiguousPolicy =
        AmbiguousLocalTimePolicy.earlierOccurrence,
  }) {
    if (windowDefinition == null) {
      return const OccurrenceMaterializationResult.failed(
        failure: OccurrenceMaterializationFailure.missingWindowDefinition,
      );
    }
    final temporal = preResolved == null
        ? instantResolver.resolve(
            localDate: blueprint.clinicalDate,
            localTime: blueprint.localTime,
            timeZone: blueprint.timeZone,
            nonexistentPolicy: nonexistentPolicy,
            ambiguousPolicy: ambiguousPolicy,
          )
        : ScheduleInstantResolutionResult.resolved(preResolved);
    if (!temporal.isResolved) {
      return OccurrenceMaterializationResult.failed(
        failure: OccurrenceMaterializationFailure.temporalResolution,
        temporalFailure: temporal.failure,
      );
    }
    try {
      final occurrenceId = identityGenerator.generate(blueprint);
      final window = windowResolver.resolve(
        targetAtUtc: temporal.value!.instantUtc,
        definition: windowDefinition,
        nextTargetAtUtc: nextTargetAtUtc,
      );
      final occurrence = RoutineOccurrence(
        occurrenceId: occurrenceId,
        routineId: blueprint.routineId,
        planId: blueprint.planId,
        scheduleId: blueprint.scheduleId,
        origin: RoutineOccurrenceOrigin.generated,
        originalWindow: window,
        currentWindow: window,
        status: RoutineOccurrenceStatus.expected,
        originalClinicalDate: blueprint.originalLocalDate,
        originalLocalTime: blueprint.originalLocalTime,
        originalTimeZone: blueprint.timeZone,
        expectationKind: blueprint.expectationKind,
        sequence: blueprint.sequence,
      );
      return OccurrenceMaterializationResult.materialized(
        occurrence: occurrence,
        resolution: temporal.value!,
      );
    } on Exception {
      return const OccurrenceMaterializationResult.failed(
        failure: OccurrenceMaterializationFailure.invalidWindow,
      );
    }
  }
}

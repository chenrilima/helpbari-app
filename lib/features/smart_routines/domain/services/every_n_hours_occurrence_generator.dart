import 'package:timezone/timezone.dart' as tz;

import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/local_date.dart';
import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/schedule_rule.dart';
import '../value_objects/typed_ids.dart';
import 'routine_eligibility_policy.dart';
import 'routine_occurrence_generator.dart';
import 'routine_occurrence_materializer.dart';
import 'schedule_instant_resolver.dart';

/// Generates fixed-duration cadence slots. DST may change their wall-clock
/// representation, but never their UTC distance from the persisted anchor.
final class EveryNHoursOccurrenceGenerator {
  const EveryNHoursOccurrenceGenerator({
    this.eligibilityPolicy = const RoutineEligibilityPolicy(),
    this.materializer = const RoutineOccurrenceMaterializer(),
  });

  final RoutineEligibilityPolicy eligibilityPolicy;
  final RoutineOccurrenceMaterializer materializer;

  RoutineOccurrenceGenerationResult generate({
    required SmartRoutine routine,
    required Iterable<RoutinePlan> plans,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutinePause> pauses,
    required DateTime startInstantInclusive,
    required DateTime endInstantExclusive,
    required int maxOccurrences,
  }) {
    if (!startInstantInclusive.isUtc || !endInstantExclusive.isUtc) {
      throw const SmartRoutineValidationException(
        'every_hours_range_requires_utc',
        'Every-hours range boundaries must be UTC.',
      );
    }
    if (maxOccurrences <= 0) {
      throw const SmartRoutineValidationException(
        'invalid_every_hours_limit',
        'maxOccurrences must be positive.',
      );
    }
    if (!startInstantInclusive.isBefore(endInstantExclusive)) {
      return RoutineOccurrenceGenerationResult(
        status: RoutineOccurrenceGenerationStatus.noBlueprints,
        occurrences: const [],
        failures: const [],
        blueprintResult: null,
      );
    }

    final planById = {for (final plan in plans) plan.planId: plan};
    final pauseInput = pauses.toList();
    final slots = <_InstantBlueprint>[];
    final failures = <OccurrenceMaterializationResult>[];
    for (final schedule in schedules.toList()) {
      final rule = schedule.rule;
      if (rule is! EveryNHoursRule) continue;
      final plan = planById[schedule.planId];
      if (plan == null) continue;
      final interval = Duration(hours: rule.intervalHours);
      var index = _firstIndex(
        rule.anchorAtUtc,
        startInstantInclusive,
        interval,
      );
      while (true) {
        final instant = rule.anchorAtUtc.add(interval * index);
        if (!instant.isBefore(endInstantExclusive)) break;
        if (slots.length >= maxOccurrences) {
          throw const SmartRoutineValidationException(
            'every_hours_limit_exceeded',
            'The requested range exceeds maxOccurrences.',
          );
        }
        final tz.Location location;
        try {
          location = schedule.timeZone.value == 'UTC'
              ? tz.UTC
              : tz.getLocation(schedule.timeZone.value);
        } on tz.LocationNotFoundException {
          failures.add(
            const OccurrenceMaterializationResult.failed(
              failure: OccurrenceMaterializationFailure.temporalResolution,
              temporalFailure: ScheduleInstantResolutionFailure.invalidTimeZone,
            ),
          );
          break;
        }
        final local = tz.TZDateTime.from(instant, location);
        final date = LocalDate.fromDateTime(local);
        final eligibility = eligibilityPolicy.evaluate(
          routine: routine,
          plan: plan,
          schedule: schedule,
          pauses: pauseInput,
          at: instant,
          localDate: date,
          allowInstantRule: true,
        );
        if (eligibility.isEligible) {
          final time = TimeOfDayValue(hour: local.hour, minute: local.minute);
          final blueprint = OccurrenceBlueprint(
            routineId: routine.routineId,
            planId: plan.planId,
            scheduleId: schedule.scheduleId,
            clinicalDate: date,
            localTime: time,
            timeZone: schedule.timeZone,
            expectationKind: ExpectationKind.recurringExpectation,
            sequence: index,
            originalLocalDate: date,
            originalLocalTime: time,
            sourceRuleType: ScheduleFrequencyType.everyNHours,
            scheduleDisplayOrder: schedule.displayOrder,
          );
          slots.add(
            _InstantBlueprint(
              blueprint,
              schedule,
              ResolvedLocalScheduleTime(
                instantUtc: instant,
                timeZone: schedule.timeZone,
                offset: local.timeZoneOffset,
                state: ScheduleInstantResolutionState.exact,
                requestedDate: date,
                requestedTime: time,
                resolvedDate: date,
                resolvedTime: time,
                diagnostic: 'absolute_interval_slot',
              ),
            ),
          );
        }
        index++;
      }
    }
    slots.sort((left, right) {
      final instant = left.resolution.instantUtc.compareTo(
        right.resolution.instantUtc,
      );
      return instant != 0 ? instant : left.blueprint.compareTo(right.blueprint);
    });
    final occurrencesById = <RoutineOccurrenceId, RoutineOccurrence>{};
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      final result = materializer.materialize(
        blueprint: slot.blueprint,
        windowDefinition: slot.schedule.windowDefinition,
        preResolved: slot.resolution,
        nextTargetAtUtc: _nextDistinctInstant(slots, index),
      );
      if (result.isMaterialized) {
        occurrencesById.putIfAbsent(
          result.occurrence!.occurrenceId,
          () => result.occurrence!,
        );
      } else {
        failures.add(result);
      }
    }
    final occurrences = occurrencesById.values.toList()
      ..sort(
        (left, right) =>
            left.originalScheduledFor.compareTo(right.originalScheduledFor),
      );
    return RoutineOccurrenceGenerationResult(
      status: occurrences.isEmpty
          ? failures.isEmpty
                ? RoutineOccurrenceGenerationStatus.noBlueprints
                : RoutineOccurrenceGenerationStatus.failed
          : failures.isEmpty
          ? RoutineOccurrenceGenerationStatus.generated
          : RoutineOccurrenceGenerationStatus.partialGeneration,
      occurrences: occurrences,
      failures: failures,
      blueprintResult: null,
    );
  }

  int _firstIndex(DateTime anchor, DateTime start, Duration interval) {
    if (!start.isAfter(anchor)) return 0;
    final micros = start.difference(anchor).inMicroseconds;
    final step = interval.inMicroseconds;
    return (micros + step - 1) ~/ step;
  }

  DateTime? _nextDistinctInstant(List<_InstantBlueprint> slots, int index) {
    final current = slots[index].resolution.instantUtc;
    for (var next = index + 1; next < slots.length; next++) {
      final candidate = slots[next].resolution.instantUtc;
      if (candidate.isAfter(current)) return candidate;
    }
    return null;
  }
}

final class _InstantBlueprint {
  const _InstantBlueprint(this.blueprint, this.schedule, this.resolution);
  final OccurrenceBlueprint blueprint;
  final RoutineSchedule schedule;
  final ResolvedLocalScheduleTime resolution;
}

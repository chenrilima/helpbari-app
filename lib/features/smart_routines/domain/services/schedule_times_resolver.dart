import '../entities/routine_schedule.dart';
import '../value_objects/local_date.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/schedule_rule.dart';
import 'eligibility_results.dart';
import 'schedule_date_eligibility_policy.dart';

final class ScheduleTimesResolver {
  const ScheduleTimesResolver({
    this.datePolicy = const ScheduleDateEligibilityPolicy(),
  });
  final ScheduleDateEligibilityPolicy datePolicy;

  ScheduleTimesResolution resolve({
    required RoutineSchedule schedule,
    required LocalDate localDate,
  }) {
    final eligibility = datePolicy.evaluate(
      rule: schedule.rule,
      localDate: localDate,
    );
    if (!eligibility.isEligible) {
      return ScheduleTimesResolution(
        times: const [],
        reason: _resolutionReason(eligibility.reason),
        expectationKind: eligibility.expectationKind,
      );
    }
    final times = switch (schedule.rule) {
      DailyAtTimesRule(:final times) ||
      SpecificWeekdaysAtTimesRule(:final times) ||
      EveryNDaysRule(:final times) ||
      WeeklyRule(:final times) ||
      MonthlyRule(:final times) => times,
      SingleDoseRule(:final scheduledAt) => [
        TimeOfDayValue(hour: scheduledAt.hour, minute: scheduledAt.minute),
      ],
      EveryNHoursRule() ||
      FreeFormRule() ||
      AsNeededRule() => const <TimeOfDayValue>[],
    };
    return ScheduleTimesResolution(
      times: times,
      reason: ScheduleTimesResolutionReason.resolved,
      expectationKind: eligibility.expectationKind,
    );
  }

  ScheduleTimesResolutionReason _resolutionReason(
    ScheduleDateEligibilityReason reason,
  ) => switch (reason) {
    ScheduleDateEligibilityReason.eligible =>
      ScheduleTimesResolutionReason.resolved,
    ScheduleDateEligibilityReason.notEligible =>
      ScheduleTimesResolutionReason.dateNotEligible,
    ScheduleDateEligibilityReason.requiresInstantEvaluation =>
      ScheduleTimesResolutionReason.requiresInstantEvaluation,
    ScheduleDateEligibilityReason.asNeeded =>
      ScheduleTimesResolutionReason.asNeeded,
    ScheduleDateEligibilityReason.unstructured =>
      ScheduleTimesResolutionReason.unstructured,
    ScheduleDateEligibilityReason.unsupported =>
      ScheduleTimesResolutionReason.unsupported,
  };
}

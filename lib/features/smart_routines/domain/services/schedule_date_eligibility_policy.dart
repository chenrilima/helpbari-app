import '../value_objects/local_date.dart';
import '../value_objects/schedule_rule.dart';
import 'eligibility_results.dart';

final class ScheduleDateEligibilityPolicy {
  const ScheduleDateEligibilityPolicy();

  ScheduleDateEligibilityResult evaluate({
    required ScheduleRule rule,
    required LocalDate localDate,
    LocalDate? anchorDate,
  }) => switch (rule) {
    DailyAtTimesRule() => _eligible(ExpectationKind.recurringExpectation),
    SpecificWeekdaysAtTimesRule(:final weekdays) =>
      weekdays.values.contains(localDate.weekday)
          ? _eligible(ExpectationKind.recurringExpectation)
          : _notEligible(),
    EveryNDaysRule(:final intervalDays) => _everyNDays(
      localDate: localDate,
      anchorDate: anchorDate,
      intervalDays: intervalDays,
    ),
    EveryNHoursRule() => const ScheduleDateEligibilityResult(
      reason: ScheduleDateEligibilityReason.requiresInstantEvaluation,
      expectationKind: ExpectationKind.unsupported,
    ),
    WeeklyRule(:final weekday) =>
      localDate.weekday == weekday
          ? _eligible(ExpectationKind.recurringExpectation)
          : _notEligible(),
    MonthlyRule(:final dayOfMonth) => _monthly(localDate, dayOfMonth),
    SingleDoseRule(:final scheduledAt) =>
      LocalDate.fromDateTime(scheduledAt) == localDate
          ? _eligible(ExpectationKind.singleExpectation)
          : _notEligible(),
    FreeFormRule() => const ScheduleDateEligibilityResult(
      reason: ScheduleDateEligibilityReason.unstructured,
      expectationKind: ExpectationKind.unstructured,
    ),
    AsNeededRule() => const ScheduleDateEligibilityResult(
      reason: ScheduleDateEligibilityReason.asNeeded,
      expectationKind: ExpectationKind.asNeeded,
    ),
  };

  ScheduleDateEligibilityResult _everyNDays({
    required LocalDate localDate,
    required LocalDate? anchorDate,
    required int intervalDays,
  }) {
    if (anchorDate == null) {
      return const ScheduleDateEligibilityResult(
        reason: ScheduleDateEligibilityReason.anchorRequired,
        expectationKind: ExpectationKind.unsupported,
      );
    }
    final days = localDate.daysSince(anchorDate);
    return days >= 0 && days % intervalDays == 0
        ? _eligible(ExpectationKind.recurringExpectation)
        : _notEligible();
  }

  ScheduleDateEligibilityResult _monthly(LocalDate date, int dayOfMonth) {
    if (dayOfMonth > date.daysInMonth) {
      return const ScheduleDateEligibilityResult(
        reason: ScheduleDateEligibilityReason.unsupported,
        expectationKind: ExpectationKind.unsupported,
      );
    }
    return date.day == dayOfMonth
        ? _eligible(ExpectationKind.recurringExpectation)
        : _notEligible();
  }

  ScheduleDateEligibilityResult _eligible(ExpectationKind kind) =>
      ScheduleDateEligibilityResult(
        reason: ScheduleDateEligibilityReason.eligible,
        expectationKind: kind,
      );

  ScheduleDateEligibilityResult _notEligible() =>
      const ScheduleDateEligibilityResult(
        reason: ScheduleDateEligibilityReason.notEligible,
        expectationKind: ExpectationKind.none,
      );
}

import 'dart:collection';

import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import 'local_date.dart';
import 'routine_values.dart';

sealed class ScheduleRule {
  const ScheduleRule(this.frequencyType);
  final ScheduleFrequencyType frequencyType;
}

final class DailyAtTimesRule extends ScheduleRule {
  DailyAtTimesRule(Iterable<TimeOfDayValue> times)
    : times = _normalizedTimes(times, 'daily_times_required'),
      super(ScheduleFrequencyType.dailyAtTimes);

  final List<TimeOfDayValue> times;
  UnmodifiableListView<TimeOfDayValue> get immutableTimes =>
      UnmodifiableListView(times);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyAtTimesRule && _listEquals(times, other.times);
  @override
  int get hashCode => Object.hash(frequencyType, Object.hashAll(times));
}

final class SpecificWeekdaysAtTimesRule extends ScheduleRule {
  SpecificWeekdaysAtTimesRule({
    required this.weekdays,
    required Iterable<TimeOfDayValue> times,
  }) : times = _normalizedTimes(times, 'weekday_times_required'),
       super(ScheduleFrequencyType.specificWeekdaysAtTimes) {
    if (weekdays.isEmpty) {
      throw const SmartRoutineValidationException(
        'weekdays_required',
        'Specific weekday frequency requires at least one weekday.',
      );
    }
  }

  final WeekdaySet weekdays;
  final List<TimeOfDayValue> times;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpecificWeekdaysAtTimesRule &&
          weekdays == other.weekdays &&
          _listEquals(times, other.times);
  @override
  int get hashCode => Object.hash(weekdays, Object.hashAll(times));
}

final class EveryNHoursRule extends ScheduleRule {
  EveryNHoursRule(this.intervalHours, {required DateTime anchorAtUtc})
    : anchorAtUtc = _requiredUtc(anchorAtUtc, 'invalid_hour_interval_anchor'),
      super(ScheduleFrequencyType.everyNHours) {
    if (intervalHours <= 0) {
      throw const SmartRoutineValidationException(
        'invalid_hour_interval',
        'Hour interval must be positive.',
      );
    }
  }
  final int intervalHours;
  final DateTime anchorAtUtc;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EveryNHoursRule &&
          intervalHours == other.intervalHours &&
          anchorAtUtc == other.anchorAtUtc;
  @override
  int get hashCode => Object.hash(frequencyType, intervalHours, anchorAtUtc);
}

DateTime _requiredUtc(DateTime value, String code) {
  if (!value.isUtc) {
    throw SmartRoutineValidationException(code, 'A UTC instant is required.');
  }
  return value;
}

final class EveryNDaysRule extends ScheduleRule {
  EveryNDaysRule({
    required this.intervalDays,
    required this.anchorDate,
    required Iterable<TimeOfDayValue> times,
  }) : times = _normalizedTimes(times, 'day_interval_times_required'),
       super(ScheduleFrequencyType.everyNDays) {
    if (intervalDays <= 0) {
      throw const SmartRoutineValidationException(
        'invalid_day_interval',
        'Day interval must be positive.',
      );
    }
  }
  final int intervalDays;
  final LocalDate anchorDate;
  final List<TimeOfDayValue> times;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EveryNDaysRule &&
          intervalDays == other.intervalDays &&
          anchorDate == other.anchorDate &&
          _listEquals(times, other.times);
  @override
  int get hashCode =>
      Object.hash(intervalDays, anchorDate, Object.hashAll(times));
}

final class WeeklyRule extends ScheduleRule {
  WeeklyRule({required this.weekday, required Iterable<TimeOfDayValue> times})
    : times = _normalizedTimes(times, 'weekly_times_required'),
      super(ScheduleFrequencyType.weekly) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw const SmartRoutineValidationException(
        'invalid_weekday',
        'Weekly frequency requires an ISO weekday 1..7.',
      );
    }
  }
  final int weekday;
  final List<TimeOfDayValue> times;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyRule &&
          weekday == other.weekday &&
          _listEquals(times, other.times);
  @override
  int get hashCode => Object.hash(weekday, Object.hashAll(times));
}

final class MonthlyRule extends ScheduleRule {
  MonthlyRule({
    required this.dayOfMonth,
    required Iterable<TimeOfDayValue> times,
  }) : times = _normalizedTimes(times, 'monthly_times_required'),
       super(ScheduleFrequencyType.monthly) {
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      throw const SmartRoutineValidationException(
        'invalid_month_day',
        'Monthly frequency day must be 1..31.',
      );
    }
  }
  final int dayOfMonth;
  final List<TimeOfDayValue> times;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyRule &&
          dayOfMonth == other.dayOfMonth &&
          _listEquals(times, other.times);
  @override
  int get hashCode => Object.hash(dayOfMonth, Object.hashAll(times));
}

final class SingleDoseRule extends ScheduleRule {
  SingleDoseRule(this.scheduledAt) : super(ScheduleFrequencyType.singleDose);
  final DateTime scheduledAt;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SingleDoseRule && scheduledAt == other.scheduledAt;
  @override
  int get hashCode => Object.hash(frequencyType, scheduledAt);
}

final class FreeFormRule extends ScheduleRule {
  FreeFormRule(String instructions)
    : instructions = _requiredText(instructions),
      super(ScheduleFrequencyType.freeForm);
  final String instructions;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeFormRule && instructions == other.instructions;
  @override
  int get hashCode => Object.hash(frequencyType, instructions);
}

final class AsNeededRule extends ScheduleRule {
  const AsNeededRule() : super(ScheduleFrequencyType.asNeeded);
  @override
  bool operator ==(Object other) => other is AsNeededRule;
  @override
  int get hashCode => frequencyType.hashCode;
}

List<TimeOfDayValue> _normalizedTimes(
  Iterable<TimeOfDayValue> values,
  String code,
) {
  final times = values.toSet().toList()..sort();
  if (times.isEmpty) {
    throw SmartRoutineValidationException(
      code,
      'At least one time is required.',
    );
  }
  return List<TimeOfDayValue>.unmodifiable(times);
}

String _requiredText(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw const SmartRoutineValidationException(
      'free_form_instructions_required',
      'Free-form frequency requires instructions.',
    );
  }
  return normalized;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

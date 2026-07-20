import 'dart:collection';

import '../errors/smart_routine_validation_exception.dart';
import 'typed_ids.dart';

final class PrescriptionItemReference {
  const PrescriptionItemReference({
    required this.prescriptionId,
    required this.prescriptionItemId,
  });

  final PrescriptionId prescriptionId;
  final PrescriptionItemId prescriptionItemId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrescriptionItemReference &&
          prescriptionId == other.prescriptionId &&
          prescriptionItemId == other.prescriptionItemId;

  @override
  int get hashCode => Object.hash(prescriptionId, prescriptionItemId);
}

final class TimeOfDayValue implements Comparable<TimeOfDayValue> {
  factory TimeOfDayValue({required int hour, required int minute}) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const SmartRoutineValidationException(
        'invalid_time_of_day',
        'Hour must be 0..23 and minute must be 0..59.',
      );
    }
    return TimeOfDayValue._(hour: hour, minute: minute);
  }

  factory TimeOfDayValue.parse(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) {
      throw const SmartRoutineValidationException(
        'invalid_time_of_day',
        'Time must use the HH:mm format.',
      );
    }
    return TimeOfDayValue._(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  const TimeOfDayValue._({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  int compareTo(TimeOfDayValue other) =>
      (hour * 60 + minute).compareTo(other.hour * 60 + other.minute);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayValue && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

final class WeekdaySet {
  WeekdaySet(Iterable<int> weekdays) : _values = _normalize(weekdays);

  final List<int> _values;

  UnmodifiableListView<int> get values => UnmodifiableListView(_values);
  bool get isEmpty => _values.isEmpty;

  static List<int> _normalize(Iterable<int> weekdays) {
    final values = weekdays.toSet();
    if (values.any(
      (value) => value < DateTime.monday || value > DateTime.sunday,
    )) {
      throw const SmartRoutineValidationException(
        'invalid_weekday',
        'Weekdays must use ISO values 1..7.',
      );
    }
    return List<int>.unmodifiable(values.toList()..sort());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekdaySet && _listEquals(_values, other._values);

  @override
  int get hashCode => Object.hashAll(_values);
}

final class IanaTimeZone {
  factory IanaTimeZone(String value) {
    final normalized = value.trim();
    final valid =
        normalized == 'UTC' ||
        RegExp(r'^[A-Za-z_]+(?:/[A-Za-z0-9_+.-]+)+$').hasMatch(normalized);
    if (!valid) {
      throw const SmartRoutineValidationException(
        'invalid_iana_time_zone',
        'A structurally valid IANA timezone or UTC is required.',
      );
    }
    return IanaTimeZone._(normalized);
  }

  const IanaTimeZone._(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IanaTimeZone && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class OccurrenceWindow {
  factory OccurrenceWindow({
    required DateTime windowStartsAt,
    required DateTime scheduledFor,
    required DateTime windowEndsAt,
  }) {
    if (windowStartsAt.isAfter(scheduledFor) ||
        scheduledFor.isAfter(windowEndsAt)) {
      throw const SmartRoutineValidationException(
        'invalid_occurrence_window',
        'Occurrence window timestamps are out of order.',
      );
    }
    return OccurrenceWindow._(
      windowStartsAt: windowStartsAt,
      scheduledFor: scheduledFor,
      windowEndsAt: windowEndsAt,
    );
  }

  const OccurrenceWindow._({
    required this.windowStartsAt,
    required this.scheduledFor,
    required this.windowEndsAt,
  });

  final DateTime windowStartsAt;
  final DateTime scheduledFor;
  final DateTime windowEndsAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OccurrenceWindow &&
          windowStartsAt == other.windowStartsAt &&
          scheduledFor == other.scheduledFor &&
          windowEndsAt == other.windowEndsAt;

  @override
  int get hashCode => Object.hash(windowStartsAt, scheduledFor, windowEndsAt);
}

final class DoseValue {
  factory DoseValue({String? value, String? unit, String? originalText}) {
    final normalizedValue = value?.trim();
    final normalizedUnit = unit?.trim();
    final normalizedOriginal = originalText?.trim();
    if ((normalizedValue == null || normalizedValue.isEmpty) &&
        (normalizedOriginal == null || normalizedOriginal.isEmpty)) {
      throw const SmartRoutineValidationException(
        'invalid_dose',
        'Dose requires a value or original text.',
      );
    }
    if (normalizedUnit != null &&
        normalizedUnit.isNotEmpty &&
        (normalizedValue == null || normalizedValue.isEmpty)) {
      throw const SmartRoutineValidationException(
        'invalid_dose_unit',
        'Dose unit requires a dose value.',
      );
    }
    return DoseValue._(
      value: normalizedValue?.isEmpty == true ? null : normalizedValue,
      unit: normalizedUnit?.isEmpty == true ? null : normalizedUnit,
      originalText: normalizedOriginal?.isEmpty == true
          ? null
          : normalizedOriginal,
    );
  }

  const DoseValue._({this.value, this.unit, this.originalText});

  final String? value;
  final String? unit;
  final String? originalText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseValue &&
          value == other.value &&
          unit == other.unit &&
          originalText == other.originalText;

  @override
  int get hashCode => Object.hash(value, unit, originalText);
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

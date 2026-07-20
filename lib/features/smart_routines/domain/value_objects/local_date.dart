import '../errors/smart_routine_validation_exception.dart';

final class LocalDate implements Comparable<LocalDate> {
  factory LocalDate({required int year, required int month, required int day}) {
    final value = DateTime.utc(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw const SmartRoutineValidationException(
        'invalid_local_date',
        'A valid calendar date is required.',
      );
    }
    return LocalDate._(year, month, day);
  }

  factory LocalDate.fromDateTime(DateTime value) =>
      LocalDate(year: value.year, month: value.month, day: value.day);

  const LocalDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  int get weekday => DateTime.utc(year, month, day).weekday;

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  int daysSince(LocalDate anchor) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;

  LocalDate addDays(int days) {
    final value = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }

  @override
  int compareTo(LocalDate other) => DateTime.utc(
    year,
    month,
    day,
  ).compareTo(DateTime.utc(other.year, other.month, other.day));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

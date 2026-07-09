import '../../../../core/services/clock_service.dart';

class RecordedAt {
  const RecordedAt(this.value, {this.clock = const AppClockService()});

  final DateTime value;
  final ClockService clock;

  bool get isToday {
    final now = clock.now();

    return now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
  }

  bool get isYesterday {
    final yesterday = clock.now().subtract(const Duration(days: 1));

    return yesterday.year == value.year &&
        yesterday.month == value.month &&
        yesterday.day == value.day;
  }

  bool get isFuture => value.isAfter(clock.now());

  @override
  String toString() {
    return value.toIso8601String();
  }
}

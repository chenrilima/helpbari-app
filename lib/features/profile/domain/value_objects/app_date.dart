import '../../../../core/services/clock_service.dart';

class AppDate {
  const AppDate(this.value, {this.clock = const AppClockService()});

  final DateTime value;
  final ClockService clock;

  int get age {
    final now = clock.now();

    var age = now.year - value.year;

    if (now.month < value.month ||
        (now.month == value.month && now.day < value.day)) {
      age--;
    }

    return age;
  }

  @override
  String toString() {
    return value.toIso8601String();
  }
}

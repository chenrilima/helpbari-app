import '../../../../core/services/clock_service.dart';

class AppointmentDate {
  const AppointmentDate(this.value, {this.clock = const AppClockService()});

  final DateTime value;
  final ClockService clock;

  bool get isUpcoming => value.isAfter(clock.now());

  String get formatted {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  @override
  String toString() => formatted;
}

class MedicationScheduleTime {
  const MedicationScheduleTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  static MedicationScheduleTime? create({
    required int hour,
    required int minute,
  }) {
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return MedicationScheduleTime(hour: hour, minute: minute);
  }

  String get formatted {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');

    return '$h:$m';
  }
}

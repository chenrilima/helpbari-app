class VitaminScheduleTime {
  const VitaminScheduleTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  static VitaminScheduleTime? create({required int hour, required int minute}) {
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return VitaminScheduleTime(hour: hour, minute: minute);
  }

  String get formatted {
    final formattedHour = hour.toString().padLeft(2, '0');
    final formattedMinute = minute.toString().padLeft(2, '0');

    return '$formattedHour:$formattedMinute';
  }

  @override
  String toString() => formatted;
}

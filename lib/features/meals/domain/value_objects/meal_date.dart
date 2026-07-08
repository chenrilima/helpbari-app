class MealDate {
  const MealDate(this.value);

  final DateTime value;

  bool get isToday {
    final now = DateTime.now();

    return now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
  }

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

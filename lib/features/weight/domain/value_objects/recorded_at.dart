class RecordedAt {
  const RecordedAt(this.value);

  final DateTime value;

  bool get isToday {
    final now = DateTime.now();

    return now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return yesterday.year == value.year &&
        yesterday.month == value.month &&
        yesterday.day == value.day;
  }

  bool get isFuture => value.isAfter(DateTime.now());

  @override
  String toString() {
    return value.toIso8601String();
  }
}

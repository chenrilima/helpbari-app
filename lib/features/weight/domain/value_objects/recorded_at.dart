class RecordedAt {
  const RecordedAt(this.value);

  final DateTime value;

  bool get isToday {
    final now = DateTime.now();

    return now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
  }

  @override
  String toString() {
    return value.toIso8601String();
  }
}

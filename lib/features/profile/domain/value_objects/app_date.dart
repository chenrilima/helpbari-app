class AppDate {
  const AppDate(this.value);

  final DateTime value;

  int get age {
    final now = DateTime.now();

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

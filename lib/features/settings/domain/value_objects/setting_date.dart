class SettingDate {
  const SettingDate(this.value);

  final DateTime value;

  String get formatted {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day/$month/$year';
  }

  @override
  String toString() {
    return formatted;
  }
}

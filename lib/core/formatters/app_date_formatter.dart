class AppDateFormatter {
  const AppDateFormatter._();

  static String short(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  static String shortWithTime(DateTime date) {
    final formattedDate = short(date);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$formattedDate • $hour:$minute';
  }
}

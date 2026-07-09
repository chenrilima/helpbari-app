abstract final class AppNumberFormatter {
  static String decimal(num value, {int fractionDigits = 1}) {
    return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
  }

  static String percentage(num value) {
    return '${value.round()}%';
  }

  static String goalProgress(num value) {
    return '${percentage(value)} da meta';
  }
}

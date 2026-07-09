abstract final class AppProteinFormatter {
  static String grams(int value) {
    return '$value g';
  }

  static String today(int value) {
    if (value <= 0) {
      return 'Proteína não informada';
    }

    return '$value g de proteína hoje';
  }

  static String meal(int value) {
    return '$value g de proteína';
  }
}

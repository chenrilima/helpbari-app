import 'app_number_formatter.dart';

abstract final class AppWaterFormatter {
  static String ml(int value) {
    if (value >= 1000) {
      return '${AppNumberFormatter.decimal(value / 1000)} L';
    }

    return '$value ml';
  }

  static String goal({required int currentMl, required int goalMl}) {
    return '${ml(currentMl)} de ${ml(goalMl)}';
  }

  static String dailyGoal(int value) {
    return 'Meta diária: ${ml(value)}';
  }

  static String registered(int value) {
    return '${ml(value)} registrado! 💧';
  }
}

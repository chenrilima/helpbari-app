import 'app_number_formatter.dart';

abstract final class AppWeightFormatter {
  static String kg(num value, {int fractionDigits = 1}) {
    return '${AppNumberFormatter.decimal(value, fractionDigits: fractionDigits)} kg';
  }

  static String difference(num value) {
    final signal = value > 0 ? '+' : '';

    return '$signal${kg(value)}';
  }

  static String remaining(num value) {
    if (value <= 0) {
      return 'Meta atingida';
    }

    return 'Faltam ${kg(value)}';
  }

  static String lostSinceStart(num value) {
    return '${kg(value)} perdidos desde o início';
  }

  static String aboveInitial(num value) {
    return '${kg(value.abs())} acima do peso inicial';
  }
}

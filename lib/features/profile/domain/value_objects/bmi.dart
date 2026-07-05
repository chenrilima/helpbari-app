import 'height.dart';
import 'weight.dart';

enum BmiClassification {
  underweight,
  normal,
  overweight,
  obesityI,
  obesityII,
  obesityIII,
}

class Bmi {
  const Bmi._(this.value);

  final double value;

  static Bmi calculate({required Weight weight, required Height height}) {
    final heightInMeters = height.valueInMeters;
    final bmi = weight.value / (heightInMeters * heightInMeters);

    return Bmi._(bmi);
  }

  BmiClassification get classification {
    if (value < 18.5) return BmiClassification.underweight;
    if (value < 25) return BmiClassification.normal;
    if (value < 30) return BmiClassification.overweight;
    if (value < 35) return BmiClassification.obesityI;
    if (value < 40) return BmiClassification.obesityII;

    return BmiClassification.obesityIII;
  }

  String get formatted {
    return value.toStringAsFixed(1);
  }

  @override
  String toString() => formatted;
}

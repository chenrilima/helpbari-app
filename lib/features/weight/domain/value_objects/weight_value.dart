class WeightValue {
  const WeightValue._(this.value);

  final double value;

  static const minValue = 20.0;
  static const maxValue = 500.0;

  static WeightValue? create(double value) {
    if (value < minValue) return null;
    if (value > maxValue) return null;

    return WeightValue._(value);
  }

  String get formatted => '${value.toStringAsFixed(1)} kg';

  @override
  String toString() => formatted;
}

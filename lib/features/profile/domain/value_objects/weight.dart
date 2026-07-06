class Weight {
  const Weight._(this.value);

  final double value;

  static const minValue = 20.0;
  static const maxValue = 500.0;

  static Weight? create(double value) {
    if (value < minValue) return null;
    if (value > maxValue) return null;

    return Weight._(value);
  }

  String get formatted {
    return '${value.toStringAsFixed(1)} kg';
  }

  @override
  String toString() => formatted;
}

class WaterAmount {
  const WaterAmount._(this.valueInMl);

  final int valueInMl;

  static const minValue = 50;
  static const maxValue = 5000;

  static WaterAmount? create(int valueInMl) {
    if (valueInMl < minValue) return null;
    if (valueInMl > maxValue) return null;

    return WaterAmount._(valueInMl);
  }

  String get formatted {
    if (valueInMl >= 1000) {
      return '${(valueInMl / 1000).toStringAsFixed(1)} L';
    }

    return '$valueInMl ml';
  }

  @override
  String toString() => formatted;
}

class Height {
  const Height._(this.valueInCentimeters);

  final int valueInCentimeters;
  static const minValue = 80;
  static const maxValue = 250;

  static Height? create(int valueInCentimeters) {
    if (valueInCentimeters < minValue) return null;
    if (valueInCentimeters > maxValue) return null;

    return Height._(valueInCentimeters);
  }

  double get valueInMeters {
    return valueInCentimeters / 100;
  }

  String get formatted {
    return '${valueInCentimeters}cm';
  }

  @override
  String toString() => formatted;
}

class MealName {
  const MealName._(this.value);

  final String value;

  static MealName? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length < 2) return null;
    if (trimmed.length > 120) return null;

    return MealName._(trimmed);
  }

  @override
  String toString() => value;
}

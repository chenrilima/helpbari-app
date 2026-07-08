class MedicationName {
  const MedicationName._(this.value);

  final String value;

  static MedicationName? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length < 2) return null;
    if (trimmed.length > 80) return null;

    return MedicationName._(trimmed);
  }
}

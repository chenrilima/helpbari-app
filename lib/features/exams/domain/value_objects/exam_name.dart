class ExamName {
  const ExamName._(this.value);

  final String value;

  static const minLength = 2;
  static const maxLength = 80;

  static ExamName? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length < minLength) return null;
    if (trimmed.length > maxLength) return null;

    return ExamName._(trimmed);
  }

  @override
  String toString() => value;
}

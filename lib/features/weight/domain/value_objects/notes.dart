class Notes {
  const Notes._(this.value);

  final String value;

  static const maxLength = 300;

  static Notes? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length > maxLength) {
      return null;
    }

    return Notes._(trimmed);
  }

  bool get isEmpty => value.isEmpty;

  bool get isNotEmpty => value.isNotEmpty;

  @override
  String toString() => value;
}

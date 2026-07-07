class VitaminName {
  const VitaminName._(this.value);

  final String value;

  static const minLength = 2;
  static const maxLength = 80;

  static VitaminName? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length < minLength) return null;
    if (trimmed.length > maxLength) return null;

    return VitaminName._(trimmed);
  }

  @override
  String toString() => value;
}

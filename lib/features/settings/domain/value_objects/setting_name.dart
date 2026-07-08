class SettingName {
  const SettingName._(this.value);

  final String value;

  static SettingName? create(String value) {
    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return null;
    }

    return SettingName._(trimmed);
  }

  @override
  String toString() {
    return value;
  }
}

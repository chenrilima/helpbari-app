enum SurgeryType {
  sleeve,
  bypass,
  duodenalSwitch,
  other;

  String get label {
    return switch (this) {
      SurgeryType.sleeve => 'Sleeve',
      SurgeryType.bypass => 'Bypass',
      SurgeryType.duodenalSwitch => 'Duodenal switch',
      SurgeryType.other => 'Outro',
    };
  }
}

extension SurgeryTypeExtension on SurgeryType {
  String get id => name;
}

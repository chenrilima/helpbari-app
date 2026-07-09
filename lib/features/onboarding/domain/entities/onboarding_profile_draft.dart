import 'dart:convert';

final class OnboardingProfileDraft {
  const OnboardingProfileDraft({
    this.name = '',
    this.surgeryDate = '',
    this.currentWeight = '',
    this.waterGoal = '',
    this.objectives = const [],
    this.notificationsEnabled = false,
  });

  factory OnboardingProfileDraft.fromJson(Map<String, Object?> json) {
    return OnboardingProfileDraft(
      name: json['name'] as String? ?? '',
      surgeryDate: json['surgeryDate'] as String? ?? '',
      currentWeight: json['currentWeight'] as String? ?? '',
      waterGoal: json['waterGoal'] as String? ?? '',
      objectives: (json['objectives'] as List<Object?>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }

  final String name;
  final String surgeryDate;
  final String currentWeight;
  final String waterGoal;
  final List<String> objectives;
  final bool notificationsEnabled;

  OnboardingProfileDraft copyWith({
    String? name,
    String? surgeryDate,
    String? currentWeight,
    String? waterGoal,
    List<String>? objectives,
    bool? notificationsEnabled,
  }) {
    return OnboardingProfileDraft(
      name: name ?? this.name,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      currentWeight: currentWeight ?? this.currentWeight,
      waterGoal: waterGoal ?? this.waterGoal,
      objectives: objectives ?? this.objectives,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'surgeryDate': surgeryDate,
      'currentWeight': currentWeight,
      'waterGoal': waterGoal,
      'objectives': objectives,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  String encode() => jsonEncode(toJson());

  static OnboardingProfileDraft decode(String value) {
    final decoded = jsonDecode(value);

    if (decoded is Map<String, Object?>) {
      return OnboardingProfileDraft.fromJson(decoded);
    }

    return const OnboardingProfileDraft();
  }
}

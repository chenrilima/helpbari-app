import 'dart:convert';

final class OnboardingProfileDraft {
  const OnboardingProfileDraft({
    this.name = '',
    this.surgeryDate = '',
    this.currentWeight = '',
    this.waterGoal = '',
    this.objectives = const [],
    this.notificationsEnabled = false,
    this.birthDate = '',
    this.height = '',
    this.initialWeight = '',
    this.targetWeight = '',
    this.surgeryType = 'other',
    this.currentWeightConfirmedAsInitial = false,
    this.waterGoalConfirmed = false,
    this.notificationsConfirmed = false,
    this.termsAccepted = false,
    this.privacyPolicyAccepted = false,
    this.currentWeightRecordId = '',
    this.trackTreatment = false,
    this.trackWater = false,
    this.trackMeals = false,
    this.trackWeight = false,
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
      birthDate: json['birthDate'] as String? ?? '',
      height: json['height'] as String? ?? '',
      initialWeight: json['initialWeight'] as String? ?? '',
      targetWeight: json['targetWeight'] as String? ?? '',
      surgeryType: json['surgeryType'] as String? ?? 'other',
      currentWeightConfirmedAsInitial:
          json['currentWeightConfirmedAsInitial'] as bool? ?? false,
      waterGoalConfirmed: json['waterGoalConfirmed'] as bool? ?? false,
      notificationsConfirmed: json['notificationsConfirmed'] as bool? ?? false,
      termsAccepted:
          json['termsAccepted'] as bool? ??
          json['documentsAccepted'] as bool? ??
          false,
      privacyPolicyAccepted:
          json['privacyPolicyAccepted'] as bool? ??
          json['documentsAccepted'] as bool? ??
          false,
      currentWeightRecordId: json['currentWeightRecordId'] as String? ?? '',
      trackTreatment: json['trackTreatment'] as bool? ?? false,
      trackWater: json['trackWater'] as bool? ?? false,
      trackMeals: json['trackMeals'] as bool? ?? false,
      trackWeight: json['trackWeight'] as bool? ?? false,
    );
  }

  final String name;
  final String surgeryDate;
  final String currentWeight;
  final String waterGoal;
  final List<String> objectives;
  final bool notificationsEnabled;
  final String birthDate;
  final String height;
  final String initialWeight;
  final String targetWeight;
  final String surgeryType;
  final bool currentWeightConfirmedAsInitial;
  final bool waterGoalConfirmed;
  final bool notificationsConfirmed;
  final bool termsAccepted;
  final bool privacyPolicyAccepted;
  final String currentWeightRecordId;
  final bool trackTreatment;
  final bool trackWater;
  final bool trackMeals;
  final bool trackWeight;

  bool get documentsAccepted => termsAccepted && privacyPolicyAccepted;

  bool get isEmpty =>
      name.isEmpty &&
      surgeryDate.isEmpty &&
      currentWeight.isEmpty &&
      waterGoal.isEmpty &&
      objectives.isEmpty &&
      birthDate.isEmpty &&
      height.isEmpty &&
      initialWeight.isEmpty &&
      targetWeight.isEmpty;

  OnboardingProfileDraft copyWith({
    String? name,
    String? surgeryDate,
    String? currentWeight,
    String? waterGoal,
    List<String>? objectives,
    bool? notificationsEnabled,
    String? birthDate,
    String? height,
    String? initialWeight,
    String? targetWeight,
    String? surgeryType,
    bool? currentWeightConfirmedAsInitial,
    bool? waterGoalConfirmed,
    bool? notificationsConfirmed,
    bool? termsAccepted,
    bool? privacyPolicyAccepted,
    String? currentWeightRecordId,
    bool? trackTreatment,
    bool? trackWater,
    bool? trackMeals,
    bool? trackWeight,
  }) {
    return OnboardingProfileDraft(
      name: name ?? this.name,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      currentWeight: currentWeight ?? this.currentWeight,
      waterGoal: waterGoal ?? this.waterGoal,
      objectives: objectives ?? this.objectives,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      initialWeight: initialWeight ?? this.initialWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      surgeryType: surgeryType ?? this.surgeryType,
      currentWeightConfirmedAsInitial:
          currentWeightConfirmedAsInitial ??
          this.currentWeightConfirmedAsInitial,
      waterGoalConfirmed: waterGoalConfirmed ?? this.waterGoalConfirmed,
      notificationsConfirmed:
          notificationsConfirmed ?? this.notificationsConfirmed,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      privacyPolicyAccepted:
          privacyPolicyAccepted ?? this.privacyPolicyAccepted,
      currentWeightRecordId:
          currentWeightRecordId ?? this.currentWeightRecordId,
      trackTreatment: trackTreatment ?? this.trackTreatment,
      trackWater: trackWater ?? this.trackWater,
      trackMeals: trackMeals ?? this.trackMeals,
      trackWeight: trackWeight ?? this.trackWeight,
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
      'birthDate': birthDate,
      'height': height,
      'initialWeight': initialWeight,
      'targetWeight': targetWeight,
      'surgeryType': surgeryType,
      'currentWeightConfirmedAsInitial': currentWeightConfirmedAsInitial,
      'waterGoalConfirmed': waterGoalConfirmed,
      'notificationsConfirmed': notificationsConfirmed,
      'termsAccepted': termsAccepted,
      'privacyPolicyAccepted': privacyPolicyAccepted,
      'currentWeightRecordId': currentWeightRecordId,
      'trackTreatment': trackTreatment,
      'trackWater': trackWater,
      'trackMeals': trackMeals,
      'trackWeight': trackWeight,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingProfileDraft && encode() == other.encode();

  @override
  int get hashCode => encode().hashCode;
}

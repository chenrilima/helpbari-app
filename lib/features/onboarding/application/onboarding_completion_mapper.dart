import '../../../../core/errors/app_exception.dart';
import '../../auth/domain/entities/auth_user.dart';
import '../../profile/domain/entities/entities.dart';
import '../../profile/domain/value_objects/value_objects.dart' as profile_vo;
import '../../settings/domain/entities/entities.dart';
import '../../weight/domain/entities/entities.dart';
import '../../weight/domain/value_objects/value_objects.dart' as weight_vo;
import '../domain/entities/entities.dart';

class OnboardingCompletionData {
  const OnboardingCompletionData({
    required this.profile,
    required this.settings,
    this.currentWeight,
  });

  final Profile profile;
  final AppSettings settings;
  final WeightRecord? currentWeight;
}

abstract final class OnboardingCompletionMapper {
  static bool canMapProfile(OnboardingProfileDraft draft) =>
      draft.name.trim().length >= 2 &&
      _parseDate(draft.birthDate) != null &&
      _parseDate(draft.surgeryDate) != null &&
      int.tryParse(draft.height.trim()) != null &&
      _initialWeight(draft) != null;

  static OnboardingCompletionData map({
    required OnboardingProfileDraft draft,
    required AuthUser user,
    required AppSettings currentSettings,
    required DateTime now,
    Profile? existingProfile,
  }) {
    final email = user.email?.trim() ?? '';
    final birthDate = _parseDate(draft.birthDate);
    final surgeryDate = _parseDate(draft.surgeryDate);
    final heightValue = int.tryParse(draft.height.trim());
    final initialValue = _initialWeight(draft);
    final targetValue = _optionalDouble(draft.targetWeight);
    final currentValue = _optionalDouble(draft.currentWeight);
    final height = heightValue == null
        ? null
        : profile_vo.Height.create(heightValue);
    final initial = initialValue == null
        ? null
        : profile_vo.Weight.create(initialValue);
    final target = targetValue == null
        ? null
        : profile_vo.Weight.create(targetValue);
    final surgeryType = profile_vo.SurgeryType.values.firstWhere(
      (value) => value.name == draft.surgeryType,
      orElse: () => profile_vo.SurgeryType.other,
    );
    final waterGoal = int.tryParse(draft.waterGoal.trim());

    if (draft.name.trim().length < 2 ||
        email.isEmpty ||
        birthDate == null ||
        surgeryDate == null ||
        height == null ||
        initial == null ||
        (targetValue != null && target == null)) {
      throw const AppException(
        code: 'onboarding.invalid_profile',
        message: 'Revise os campos obrigatórios do perfil.',
      );
    }
    if (draft.trackWater &&
        (!draft.waterGoalConfirmed ||
            waterGoal == null ||
            waterGoal < 500 ||
            waterGoal > 6000)) {
      throw const AppException(
        code: 'onboarding.invalid_water_goal',
        message: 'Confirme uma meta de água entre 500 e 6000 ml.',
      );
    }
    if (!draft.notificationsConfirmed) {
      throw const AppException(
        code: 'onboarding.notifications_not_confirmed',
        message: 'Confirme sua escolha de notificações.',
      );
    }

    final profile = Profile(
      id: existingProfile?.id ?? user.id,
      name: draft.name.trim(),
      email: email,
      createdAt: existingProfile?.createdAt ?? profile_vo.AppDate(now),
      birthDate: profile_vo.AppDate(birthDate),
      height: height,
      initialWeight: initial,
      targetWeight: target,
      surgeryDate: profile_vo.AppDate(surgeryDate),
      surgeryType: surgeryType,
      photoUrl: existingProfile?.photoUrl,
      photoStoragePath: existingProfile?.photoStoragePath,
    );
    final settings = currentSettings.copyWith(
      dailyWaterGoalMl: draft.trackWater
          ? waterGoal
          : currentSettings.dailyWaterGoalMl,
      vitaminRemindersEnabled: draft.notificationsEnabled,
      medicationRemindersEnabled: draft.notificationsEnabled,
      appointmentRemindersEnabled: draft.notificationsEnabled,
      treatmentTrackingEnabled: draft.trackTreatment,
      waterTrackingEnabled: draft.trackWater,
      mealTrackingEnabled: draft.trackMeals,
      weightTrackingEnabled: draft.trackWeight,
    );
    final weight = currentValue == null
        ? null
        : weight_vo.WeightValue.create(currentValue);
    if (currentValue != null && weight == null) {
      throw const AppException(
        code: 'onboarding.invalid_current_weight',
        message: 'Revise o peso atual informado.',
      );
    }
    if (weight != null && draft.currentWeightRecordId.isEmpty) {
      throw const AppException(
        code: 'onboarding.missing_weight_record_id',
        message: 'Não foi possível preparar o registro de peso.',
      );
    }

    return OnboardingCompletionData(
      profile: profile,
      settings: settings,
      currentWeight: weight == null
          ? null
          : WeightRecord(
              id: draft.currentWeightRecordId,
              weight: weight,
              recordedAt: weight_vo.RecordedAt(now),
              notes: weight_vo.Notes.create(
                'Peso atual informado no onboarding.',
              ),
            ),
    );
  }

  static double? _initialWeight(OnboardingProfileDraft draft) {
    final explicit = _optionalDouble(draft.initialWeight);
    if (explicit != null) return explicit;
    return draft.currentWeightConfirmedAsInitial
        ? _optionalDouble(draft.currentWeight)
        : null;
  }

  static double? _optionalDouble(String raw) {
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  static DateTime? _parseDate(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final value = DateTime(year, month, day);
    return value.day == day && value.month == month && value.year == year
        ? value
        : null;
  }
}

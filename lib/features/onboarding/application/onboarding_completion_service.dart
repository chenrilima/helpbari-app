import '../../auth/domain/entities/auth_user.dart';
import '../../privacy/domain/entities/entities.dart';
import '../../privacy/domain/usecases/use_cases.dart';
import '../../profile/domain/entities/entities.dart';
import '../../profile/domain/usecases/use_cases.dart';
import '../../settings/domain/entities/entities.dart';
import '../../settings/domain/usecases/use_cases.dart';
import '../../weight/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';
import '../domain/usecases/use_cases.dart';
import 'onboarding_completion_mapper.dart';

class OnboardingCompletionResult {
  const OnboardingCompletionResult({
    required this.profile,
    required this.settings,
    required this.consent,
  });

  final Profile profile;
  final AppSettings settings;
  final PrivacyConsent consent;
}

class OnboardingCompletionService {
  const OnboardingCompletionService({
    required OnboardingUseCases onboarding,
    required ProfileUseCases profile,
    required SettingsUseCases settings,
    required WeightUseCases weight,
    required PrivacyUseCases privacy,
    required DateTime Function() now,
  }) : _onboarding = onboarding,
       _profile = profile,
       _settings = settings,
       _weight = weight,
       _privacy = privacy,
       _now = now;

  final OnboardingUseCases _onboarding;
  final ProfileUseCases _profile;
  final SettingsUseCases _settings;
  final WeightUseCases _weight;
  final PrivacyUseCases _privacy;
  final DateTime Function() _now;

  Future<OnboardingCompletionResult> complete({
    required OnboardingProfileDraft draft,
    required AuthUser user,
  }) async {
    _onboarding.validateLegalAcceptance(draft);
    final existingProfile = await _profile.getProfile();
    var confirmedProfile = existingProfile;
    var confirmedSettings = await _settings.getSettings();

    if (existingProfile == null ||
        OnboardingCompletionMapper.canMapProfile(draft)) {
      final data = OnboardingCompletionMapper.map(
        draft: draft,
        user: user,
        currentSettings: confirmedSettings,
        existingProfile: existingProfile,
        now: _now(),
      );
      if (existingProfile == null) {
        await _profile.saveProfile(data.profile);
      } else {
        await _profile.updateProfile(data.profile);
      }
      await _settings.saveSettings(data.settings);
      if (data.currentWeight != null) {
        final history = await _weight.getHistory();
        final alreadyExists = history.any(
          (record) => record.id == data.currentWeight!.id,
        );
        if (alreadyExists) {
          await _weight.update(data.currentWeight!);
        } else {
          await _weight.register(data.currentWeight!);
        }
      }
      confirmedProfile = data.profile;
      confirmedSettings = data.settings;
    }

    if (confirmedProfile == null) {
      throw StateError('Perfil obrigatório não foi persistido.');
    }
    final consent = await _privacy.acceptCurrentDocuments();
    if (!await _privacy.hasCurrentConsent()) {
      throw StateError('O aceite dos documentos não foi persistido.');
    }
    return OnboardingCompletionResult(
      profile: confirmedProfile,
      settings: confirmedSettings,
      consent: consent,
    );
  }
}

import '../entities/entities.dart';

abstract interface class OnboardingRepository {
  bool hasCompletedOnboarding();

  OnboardingProfileDraft getDraft();

  Future<void> saveDraft(OnboardingProfileDraft draft);

  Future<void> complete(OnboardingProfileDraft draft);
}

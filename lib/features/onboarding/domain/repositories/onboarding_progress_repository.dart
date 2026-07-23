import '../entities/onboarding_progress.dart';

abstract interface class OnboardingProgressRepository {
  Future<OnboardingProgress?> getForUser();
  Future<void> save(OnboardingProgress progress);
}

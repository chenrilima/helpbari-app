import '../entities/entities.dart';

abstract interface class OnboardingRepository {
  bool hasCompletedIntroduction();
  bool hasCompletedForUser(String userId);
  bool hasConsumedDraft(String userId);
  int getResumeStep(String? userId);

  OnboardingProfileDraft getDraft();

  Future<void> saveDraft(OnboardingProfileDraft draft);

  Future<void> completeIntroduction();
  Future<void> saveResumeStep(String? userId, int step);
  Future<void> completeForUser(String userId);
  Future<void> markDraftConsumed(String userId);
}

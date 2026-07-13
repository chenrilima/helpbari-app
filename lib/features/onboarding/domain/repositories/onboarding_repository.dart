import '../entities/entities.dart';

abstract interface class OnboardingRepository {
  bool hasCompletedIntroduction();
  bool hasCompletedForUser(String userId);
  bool hasConsumedDraft(String userId);
  int getResumeStep(String? userId);

  OnboardingProfileDraft getDraft(String? userId);

  Future<void> saveDraft(String? userId, OnboardingProfileDraft draft);
  Future<void> claimPreAuthDraft(String userId);
  Future<void> clearDraft(String userId);

  Future<void> completeIntroduction();
  Future<void> saveResumeStep(String? userId, int step);
  Future<void> completeForUser(String userId);
  Future<void> markDraftConsumed(String userId);
}

import '../entities/entities.dart';
import '../repositories/repositories.dart';

final class OnboardingUseCases {
  const OnboardingUseCases(this.repository);
  final OnboardingRepository repository;

  bool hasCompletedIntroduction() => repository.hasCompletedIntroduction();
  bool hasCompletedForUser(String userId) =>
      repository.hasCompletedForUser(userId);
  bool hasConsumedDraft(String userId) => repository.hasConsumedDraft(userId);
  int getResumeStep(String? userId) => repository.getResumeStep(userId);
  OnboardingProfileDraft getDraft() => repository.getDraft();
  Future<void> saveDraft(OnboardingProfileDraft draft) =>
      repository.saveDraft(draft);
  Future<void> completeIntroduction() => repository.completeIntroduction();
  Future<void> saveResumeStep(String? userId, int step) =>
      repository.saveResumeStep(userId, step);
  Future<void> completeForUser(String userId) =>
      repository.completeForUser(userId);
  Future<void> markDraftConsumed(String userId) =>
      repository.markDraftConsumed(userId);
}

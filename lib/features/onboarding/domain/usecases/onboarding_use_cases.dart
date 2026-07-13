import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../../../../core/errors/app_exception.dart';

final class OnboardingUseCases {
  const OnboardingUseCases(this.repository);
  final OnboardingRepository repository;

  bool hasCompletedIntroduction() => repository.hasCompletedIntroduction();
  bool hasCompletedForUser(String userId) =>
      repository.hasCompletedForUser(userId);
  bool hasConsumedDraft(String userId) => repository.hasConsumedDraft(userId);
  int getResumeStep(String? userId) => repository.getResumeStep(userId);
  OnboardingProfileDraft getDraft(String? userId) =>
      repository.getDraft(userId);
  Future<void> saveDraft(String? userId, OnboardingProfileDraft draft) =>
      repository.saveDraft(userId, draft);
  Future<void> claimPreAuthDraft(String userId) =>
      repository.claimPreAuthDraft(userId);
  Future<void> clearDraft(String userId) => repository.clearDraft(userId);
  Future<void> completeIntroduction() => repository.completeIntroduction();
  Future<void> saveResumeStep(String? userId, int step) =>
      repository.saveResumeStep(userId, step);
  Future<void> completeForUser(String userId) =>
      repository.completeForUser(userId);
  Future<void> markDraftConsumed(String userId) =>
      repository.markDraftConsumed(userId);

  void validateLegalAcceptance(OnboardingProfileDraft draft) {
    if (draft.termsAccepted && draft.privacyPolicyAccepted) return;
    throw const AppException(
      code: 'onboarding.legal_acceptance_required',
      message:
          'Aceite os Termos de Uso e a Política de Privacidade para continuar.',
    );
  }
}

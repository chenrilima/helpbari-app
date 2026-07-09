import '../entities/entities.dart';
import '../repositories/repositories.dart';

final class GetOnboardingStatusUseCase {
  const GetOnboardingStatusUseCase(this._repository);

  final OnboardingRepository _repository;

  bool call() => _repository.hasCompletedOnboarding();
}

final class GetOnboardingDraftUseCase {
  const GetOnboardingDraftUseCase(this._repository);

  final OnboardingRepository _repository;

  OnboardingProfileDraft call() => _repository.getDraft();
}

final class SaveOnboardingDraftUseCase {
  const SaveOnboardingDraftUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call(OnboardingProfileDraft draft) {
    return _repository.saveDraft(draft);
  }
}

final class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call(OnboardingProfileDraft draft) {
    return _repository.complete(draft);
  }
}

final class OnboardingUseCases {
  const OnboardingUseCases({
    required this.getStatus,
    required this.getDraft,
    required this.saveDraft,
    required this.complete,
  });

  final GetOnboardingStatusUseCase getStatus;
  final GetOnboardingDraftUseCase getDraft;
  final SaveOnboardingDraftUseCase saveDraft;
  final CompleteOnboardingUseCase complete;
}

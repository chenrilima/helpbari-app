import '../../privacy/domain/usecases/use_cases.dart';
import '../../profile/domain/usecases/use_cases.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/repositories.dart';
import '../domain/usecases/use_cases.dart';

final class OnboardingProgressService {
  const OnboardingProgressService({
    required OnboardingProgressRepository repository,
    required OnboardingUseCases legacy,
    required ProfileUseCases profile,
    required PrivacyUseCases privacy,
    required String Function() newId,
    required DateTime Function() now,
  }) : _repository = repository,
       _legacy = legacy,
       _profile = profile,
       _privacy = privacy,
       _newId = newId,
       _now = now;

  final OnboardingProgressRepository _repository;
  final OnboardingUseCases _legacy;
  final ProfileUseCases _profile;
  final PrivacyUseCases _privacy;
  final String Function() _newId;
  final DateTime Function() _now;

  Future<OnboardingProgress> resolve(String userId) async {
    final existing = await _repository.getForUser();
    if (existing != null) {
      final validated = _validate(existing);
      if (validated.isCurrentCompleted) return validated;
      final profile = await _profile.getProfile();
      final hasConsent = await _privacy.hasCurrentConsent();
      // Compatibility backfill is also required when a previous app version
      // created the V1 row before it persisted the terminal status. Profile
      // plus current legal consent are the approved legacy completion proof.
      if (profile != null && hasConsent) {
        final now = _now().toUtc();
        final completed = validated.copyWith(
          onboardingVersion: OnboardingV1Contract.version,
          status: OnboardingProgressStatus.completed,
          clearCurrentStep: true,
          completedStepIds: OnboardingV1Contract.stepIds.toSet(),
          startedAt: validated.startedAt ?? now,
          completedAt: validated.completedAt ?? now,
          updatedAt: now,
        );
        await _repository.save(completed);
        return completed;
      }
      if (validated.onboardingVersion < OnboardingV1Contract.version) {
        final migrated = validated.copyWith(
          onboardingVersion: OnboardingV1Contract.version,
          status: OnboardingProgressStatus.needsReview,
          currentStepId: profile == null ? 'basicProfile' : 'legalConsents',
          completedStepIds: validated.completedStepIds,
          completedAt: validated.completedAt,
          clearCompletedAt: true,
          updatedAt: _now().toUtc(),
        );
        await _repository.save(migrated);
        return migrated;
      }
      return validated;
    }

    final profile = await _profile.getProfile();
    final hasConsent = await _privacy.hasCurrentConsent();
    final now = _now().toUtc();
    final legacyStepId = _legacyStepId(_legacy.getResumeStep(userId));
    final hasDraft = !_legacy.getDraft(userId).isEmpty;
    final legacyCompleted = _legacy.hasCompletedForUser(userId);

    final status = profile != null && hasConsent
        ? OnboardingProgressStatus.completed
        : profile != null
        ? OnboardingProgressStatus.needsReview
        : legacyCompleted
        ? OnboardingProgressStatus.needsReview
        : hasDraft
        ? OnboardingProgressStatus.inProgress
        : OnboardingProgressStatus.notStarted;
    final completed = status == OnboardingProgressStatus.completed;
    final progress = OnboardingProgress(
      id: _newId(),
      userId: userId,
      onboardingVersion: OnboardingV1Contract.version,
      status: status,
      currentStepId: completed
          ? null
          : profile != null && !hasConsent
          ? 'legalConsents'
          : legacyCompleted
          ? 'basicProfile'
          : legacyStepId,
      completedStepIds: completed
          ? OnboardingV1Contract.stepIds.toSet()
          : <String>{},
      startedAt: hasDraft || profile != null || legacyCompleted ? now : null,
      completedAt: completed ? now : null,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(progress);
    return progress;
  }

  Future<OnboardingProgress> saveStep({
    required OnboardingProgress progress,
    required String currentStepId,
    String? completedStepId,
  }) async {
    if (!OnboardingV1Contract.isKnownStep(currentStepId) ||
        !OnboardingV1Contract.isKnownStep(completedStepId)) {
      throw StateError('Unknown onboarding step.');
    }
    final completed = {...progress.completedStepIds};
    if (completedStepId != null) completed.add(completedStepId);
    final updated = progress.copyWith(
      status: OnboardingProgressStatus.inProgress,
      currentStepId: currentStepId,
      completedStepIds: completed,
      startedAt: progress.startedAt ?? _now().toUtc(),
      clearCompletedAt: true,
      updatedAt: _now().toUtc(),
    );
    await _repository.save(updated);
    return updated;
  }

  Future<OnboardingProgress> complete(OnboardingProgress progress) async {
    if (progress.isCurrentCompleted) return progress;
    final now = _now().toUtc();
    final updated = progress.copyWith(
      onboardingVersion: OnboardingV1Contract.version,
      status: OnboardingProgressStatus.completed,
      clearCurrentStep: true,
      completedStepIds: OnboardingV1Contract.stepIds.toSet(),
      startedAt: progress.startedAt ?? now,
      completedAt: now,
      updatedAt: now,
    );
    await _repository.save(updated);
    return updated;
  }

  OnboardingProgress _validate(OnboardingProgress value) {
    if (value.userId.isEmpty ||
        !OnboardingV1Contract.isKnownStep(value.currentStepId) ||
        value.completedStepIds.any(
          (step) => !OnboardingV1Contract.stepIds.contains(step),
        )) {
      return value.copyWith(
        status: OnboardingProgressStatus.needsReview,
        currentStepId: 'basicProfile',
      );
    }
    return value;
  }

  String _legacyStepId(int index) => switch (index) {
    0 || 1 || 2 || 3 || 4 => 'welcome',
    5 => 'basicProfile',
    6 => 'legalConsents',
    7 => 'completion',
    _ => 'welcome',
  };
}

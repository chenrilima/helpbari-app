import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/onboarding/domain/services/onboarding_progress_merge_policy.dart';

void main() {
  test('local completed wins over newer incomplete remote states', () {
    final completedAt = DateTime.utc(2026, 7, 20);
    final local = _progress(
      OnboardingProgressStatus.completed,
      updatedAt: completedAt,
      completedAt: completedAt,
    );

    for (final status in <OnboardingProgressStatus>[
      OnboardingProgressStatus.notStarted,
      OnboardingProgressStatus.inProgress,
      OnboardingProgressStatus.needsReview,
    ]) {
      final merged = OnboardingProgressMergePolicy.merge(
        local,
        _progress(status, updatedAt: DateTime.utc(2026, 7, 22)),
      );
      expect(merged.status, OnboardingProgressStatus.completed);
      expect(merged.completedAt, completedAt);
    }
  });

  test('remote completed promotes local and preserves first completedAt', () {
    final remoteCompletedAt = DateTime.utc(2026, 7, 21);
    final merged = OnboardingProgressMergePolicy.merge(
      _progress(
        OnboardingProgressStatus.inProgress,
        updatedAt: DateTime.utc(2026, 7, 22),
      ),
      _progress(
        OnboardingProgressStatus.completed,
        updatedAt: remoteCompletedAt,
        completedAt: remoteCompletedAt,
      ),
    );

    expect(merged.status, OnboardingProgressStatus.completed);
    expect(merged.completedAt, remoteCompletedAt);
  });

  test('repeated merge is idempotent', () {
    final local = _progress(
      OnboardingProgressStatus.completed,
      updatedAt: DateTime.utc(2026, 7, 22),
      completedAt: DateTime.utc(2026, 7, 20),
    );
    final remote = _progress(
      OnboardingProgressStatus.inProgress,
      updatedAt: DateTime.utc(2026, 7, 23),
    );

    final first = OnboardingProgressMergePolicy.merge(local, remote);
    final second = OnboardingProgressMergePolicy.merge(first, remote);

    expect(second, first);
    expect(second.updatedAt, local.updatedAt);
  });
}

OnboardingProgress _progress(
  OnboardingProgressStatus status, {
  required DateTime updatedAt,
  DateTime? completedAt,
}) => OnboardingProgress(
  id: 'state-a',
  userId: 'user-a',
  onboardingVersion: OnboardingV1Contract.version,
  status: status,
  currentStepId: status == OnboardingProgressStatus.completed
      ? null
      : 'basicProfile',
  completedStepIds: status == OnboardingProgressStatus.completed
      ? OnboardingV1Contract.stepIds.toSet()
      : const {'welcome'},
  startedAt: DateTime.utc(2026, 7, 19),
  completedAt: completedAt,
  createdAt: DateTime.utc(2026, 7, 19),
  updatedAt: updatedAt,
);

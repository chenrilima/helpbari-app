import '../entities/onboarding_progress.dart';

abstract final class OnboardingProgressMergePolicy {
  static OnboardingProgress merge(
    OnboardingProgress local,
    OnboardingProgress remote,
  ) {
    if (local.userId != remote.userId) {
      throw StateError(
        'Cannot merge onboarding progress from different users.',
      );
    }

    final localRank = _rank(local.status);
    final remoteRank = _rank(remote.status);
    final selected = remoteRank > localRank
        ? remote
        : localRank > remoteRank
        ? local
        : remote.updatedAt.isAfter(local.updatedAt)
        ? remote
        : local;

    if (local.isCurrentCompleted || remote.isCurrentCompleted) {
      final firstCompletedAt = _earliest(local.completedAt, remote.completedAt);
      final completed = selected.isCurrentCompleted
          ? selected
          : local.isCurrentCompleted
          ? local
          : remote;
      return completed.copyWith(
        status: OnboardingProgressStatus.completed,
        clearCurrentStep: true,
        completedStepIds: {
          ...local.completedStepIds,
          ...remote.completedStepIds,
        },
        completedAt: firstCompletedAt ?? completed.completedAt,
      );
    }
    return selected;
  }

  static int _rank(OnboardingProgressStatus status) => switch (status) {
    OnboardingProgressStatus.notStarted => 0,
    OnboardingProgressStatus.inProgress ||
    OnboardingProgressStatus.needsReview => 1,
    OnboardingProgressStatus.completed => 2,
  };

  static DateTime? _earliest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }
}

enum OnboardingProgressStatus { notStarted, inProgress, completed, needsReview }

abstract final class OnboardingV1Contract {
  static const version = 1;
  static const stepIds = <String>[
    'welcome',
    'legalConsents',
    'basicProfile',
    'bariatricJourney',
    'weightAndGoals',
    'trackingPreferences',
    'trackingConfiguration',
    'reminderPreference',
    'completion',
  ];

  static bool isKnownStep(String? value) =>
      value == null || stepIds.contains(value);
}

final class OnboardingProgress {
  const OnboardingProgress({
    required this.id,
    required this.userId,
    required this.onboardingVersion,
    required this.status,
    required this.completedStepIds,
    required this.createdAt,
    required this.updatedAt,
    this.currentStepId,
    this.startedAt,
    this.completedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final int onboardingVersion;
  final OnboardingProgressStatus status;
  final String? currentStepId;
  final Set<String> completedStepIds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isCurrentCompleted =>
      onboardingVersion >= OnboardingV1Contract.version &&
      status == OnboardingProgressStatus.completed &&
      deletedAt == null;

  OnboardingProgress copyWith({
    int? onboardingVersion,
    OnboardingProgressStatus? status,
    String? currentStepId,
    bool clearCurrentStep = false,
    Set<String>? completedStepIds,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => OnboardingProgress(
    id: id,
    userId: userId,
    onboardingVersion: onboardingVersion ?? this.onboardingVersion,
    status: status ?? this.status,
    currentStepId: clearCurrentStep
        ? null
        : currentStepId ?? this.currentStepId,
    completedStepIds: completedStepIds ?? this.completedStepIds,
    startedAt: startedAt ?? this.startedAt,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingProgress &&
          id == other.id &&
          userId == other.userId &&
          onboardingVersion == other.onboardingVersion &&
          status == other.status &&
          currentStepId == other.currentStepId &&
          _sameSteps(completedStepIds, other.completedStepIds) &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    onboardingVersion,
    status,
    currentStepId,
    Object.hashAll(completedStepIds.toList()..sort()),
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );

  static bool _sameSteps(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);
}

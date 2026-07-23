import '../../domain/entities/entities.dart';

enum OnboardingStep {
  splash,
  welcome,
  benefits,
  permissions,
  goals,
  initialData,
  documents,
  completion,
}

enum AppEntryStatus {
  loading,
  unauthenticated,
  authenticatedOnboardingPending,
  authenticatedLegalAcceptancePending,
  authenticatedReady,
  failure,
}

final class OnboardingState {
  const OnboardingState({
    required this.introductionCompleted,
    required this.userCompleted,
    required this.isAuthenticated,
    required this.draft,
    this.currentStep = OnboardingStep.splash,
    this.isSaving = false,
    this.isResolvingSession = false,
    this.hasProfile = false,
    this.hasCurrentLegalConsent = false,
    this.requiresConsentReview = false,
    this.resolutionFailed = false,
    this.errorMessage,
    this.canonicalProgress,
  });

  final bool introductionCompleted;
  final bool userCompleted;
  final bool isAuthenticated;
  final OnboardingProfileDraft draft;
  final OnboardingStep currentStep;
  final bool isSaving;
  final bool isResolvingSession;
  final bool hasProfile;
  final bool hasCurrentLegalConsent;
  final bool requiresConsentReview;
  final bool resolutionFailed;
  final String? errorMessage;
  final OnboardingProgress? canonicalProgress;

  bool get hasCompleted =>
      isAuthenticated ? userCompleted : introductionCompleted;
  int get currentIndex => OnboardingStep.values.indexOf(currentStep);
  int get totalSteps => OnboardingStep.values.length;
  double get progress => (currentIndex + 1) / totalSteps;
  bool get isFirstStep => currentIndex == 0;
  bool get isLastStep => currentIndex == totalSteps - 1;
  bool get legalAcceptancePending =>
      isAuthenticated && hasProfile && !hasCurrentLegalConsent;
  AppEntryStatus get entryStatus {
    if (!isAuthenticated) return AppEntryStatus.unauthenticated;
    if (isResolvingSession) return AppEntryStatus.loading;
    if (userCompleted) return AppEntryStatus.authenticatedReady;
    if (resolutionFailed) return AppEntryStatus.failure;
    if (hasProfile && !hasCurrentLegalConsent) {
      return AppEntryStatus.authenticatedLegalAcceptancePending;
    }
    return AppEntryStatus.authenticatedOnboardingPending;
  }

  OnboardingState copyWith({
    bool? introductionCompleted,
    bool? userCompleted,
    bool? isAuthenticated,
    OnboardingProfileDraft? draft,
    OnboardingStep? currentStep,
    bool? isSaving,
    bool? isResolvingSession,
    bool? hasProfile,
    bool? hasCurrentLegalConsent,
    bool? requiresConsentReview,
    bool? resolutionFailed,
    String? errorMessage,
    bool clearError = false,
    OnboardingProgress? canonicalProgress,
    bool clearCanonicalProgress = false,
  }) => OnboardingState(
    introductionCompleted: introductionCompleted ?? this.introductionCompleted,
    userCompleted: userCompleted ?? this.userCompleted,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    draft: draft ?? this.draft,
    currentStep: currentStep ?? this.currentStep,
    isSaving: isSaving ?? this.isSaving,
    isResolvingSession: isResolvingSession ?? this.isResolvingSession,
    hasProfile: hasProfile ?? this.hasProfile,
    hasCurrentLegalConsent:
        hasCurrentLegalConsent ?? this.hasCurrentLegalConsent,
    requiresConsentReview: requiresConsentReview ?? this.requiresConsentReview,
    resolutionFailed: resolutionFailed ?? this.resolutionFailed,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    canonicalProgress: clearCanonicalProgress
        ? null
        : canonicalProgress ?? this.canonicalProgress,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingState &&
          introductionCompleted == other.introductionCompleted &&
          userCompleted == other.userCompleted &&
          isAuthenticated == other.isAuthenticated &&
          draft == other.draft &&
          currentStep == other.currentStep &&
          isSaving == other.isSaving &&
          isResolvingSession == other.isResolvingSession &&
          hasProfile == other.hasProfile &&
          hasCurrentLegalConsent == other.hasCurrentLegalConsent &&
          requiresConsentReview == other.requiresConsentReview &&
          resolutionFailed == other.resolutionFailed &&
          errorMessage == other.errorMessage &&
          canonicalProgress == other.canonicalProgress;

  @override
  int get hashCode => Object.hash(
    introductionCompleted,
    userCompleted,
    isAuthenticated,
    draft,
    currentStep,
    isSaving,
    isResolvingSession,
    hasProfile,
    hasCurrentLegalConsent,
    requiresConsentReview,
    resolutionFailed,
    errorMessage,
    canonicalProgress,
  );
}

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

final class OnboardingState {
  const OnboardingState({
    required this.introductionCompleted,
    required this.userCompleted,
    required this.isAuthenticated,
    required this.draft,
    this.currentStep = OnboardingStep.splash,
    this.isSaving = false,
    this.errorMessage,
  });

  final bool introductionCompleted;
  final bool userCompleted;
  final bool isAuthenticated;
  final OnboardingProfileDraft draft;
  final OnboardingStep currentStep;
  final bool isSaving;
  final String? errorMessage;

  bool get hasCompleted =>
      isAuthenticated ? userCompleted : introductionCompleted;
  int get currentIndex => OnboardingStep.values.indexOf(currentStep);
  int get totalSteps => OnboardingStep.values.length;
  double get progress => (currentIndex + 1) / totalSteps;
  bool get isFirstStep => currentIndex == 0;
  bool get isLastStep => currentIndex == totalSteps - 1;

  OnboardingState copyWith({
    bool? introductionCompleted,
    bool? userCompleted,
    bool? isAuthenticated,
    OnboardingProfileDraft? draft,
    OnboardingStep? currentStep,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => OnboardingState(
    introductionCompleted: introductionCompleted ?? this.introductionCompleted,
    userCompleted: userCompleted ?? this.userCompleted,
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    draft: draft ?? this.draft,
    currentStep: currentStep ?? this.currentStep,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

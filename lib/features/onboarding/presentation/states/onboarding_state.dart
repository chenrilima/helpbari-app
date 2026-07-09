import '../../domain/entities/entities.dart';

enum OnboardingStep {
  splash,
  welcome,
  benefits,
  permissions,
  goals,
  initialData,
  completion,
}

final class OnboardingState {
  const OnboardingState({
    required this.hasCompleted,
    required this.draft,
    this.currentStep = OnboardingStep.splash,
    this.isSaving = false,
  });

  final bool hasCompleted;
  final OnboardingProfileDraft draft;
  final OnboardingStep currentStep;
  final bool isSaving;

  int get currentIndex => OnboardingStep.values.indexOf(currentStep);

  int get totalSteps => OnboardingStep.values.length;

  double get progress => (currentIndex + 1) / totalSteps;

  bool get isFirstStep => currentIndex == 0;

  bool get isLastStep => currentIndex == totalSteps - 1;

  OnboardingState copyWith({
    bool? hasCompleted,
    OnboardingProfileDraft? draft,
    OnboardingStep? currentStep,
    bool? isSaving,
  }) {
    return OnboardingState(
      hasCompleted: hasCompleted ?? this.hasCompleted,
      draft: draft ?? this.draft,
      currentStep: currentStep ?? this.currentStep,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

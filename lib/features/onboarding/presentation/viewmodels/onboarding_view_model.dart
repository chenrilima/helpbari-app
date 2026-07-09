import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/onboarding_providers.dart';
import '../states/onboarding_state.dart';

class OnboardingViewModel extends Notifier<OnboardingState> {
  late final OnboardingUseCases _useCases;

  @override
  OnboardingState build() {
    _useCases = ref.watch(onboardingUseCasesProvider);

    return OnboardingState(
      hasCompleted: _useCases.getStatus(),
      draft: _useCases.getDraft(),
    );
  }

  void next() {
    if (state.isLastStep) return;

    state = state.copyWith(
      currentStep: OnboardingStep.values[state.currentIndex + 1],
    );
  }

  void previous() {
    if (state.isFirstStep) return;

    state = state.copyWith(
      currentStep: OnboardingStep.values[state.currentIndex - 1],
    );
  }

  Future<void> skip() => complete();

  Future<void> complete() async {
    state = state.copyWith(isSaving: true);
    await _useCases.complete(state.draft);
    state = state.copyWith(hasCompleted: true, isSaving: false);
  }

  Future<void> updateDraft(OnboardingProfileDraft draft) async {
    state = state.copyWith(draft: draft);
    await _useCases.saveDraft(draft);
  }

  Future<void> setNotificationsEnabled(bool value) {
    return updateDraft(state.draft.copyWith(notificationsEnabled: value));
  }

  Future<void> toggleObjective(String objective) {
    final objectives = [...state.draft.objectives];

    if (objectives.contains(objective)) {
      objectives.remove(objective);
    } else {
      objectives.add(objective);
    }

    return updateDraft(state.draft.copyWith(objectives: objectives));
  }
}

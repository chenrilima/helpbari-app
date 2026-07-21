import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/bootstrap/sync_bootstrap_provider.dart';
import '../../../../core/errors/presentation_error_mapper.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../privacy/presentation/providers/privacy_providers.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../profile/presentation/providers/profile_view_model_provider.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../settings/presentation/providers/setting_view_model_provider.dart';
import '../../../settings/presentation/providers/settings_reminder_sync_provider.dart';
import '../../../water/presentation/providers/water_view_model_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/onboarding_providers.dart';
import '../states/onboarding_state.dart';

class OnboardingViewModel extends Notifier<OnboardingState> {
  OnboardingUseCases get _useCases => ref.read(onboardingUseCasesProvider);
  Completer<void>? _disposed;

  @override
  OnboardingState build() {
    _disposed = Completer<void>();
    ref.onDispose(() {
      final disposed = _disposed;
      if (disposed != null && !disposed.isCompleted) disposed.complete();
    });
    final user = ref.watch(authSessionProvider);
    final consumed = user != null && _useCases.hasConsumedDraft(user.id);
    final resume = _useCases
        .getResumeStep(user?.id)
        .clamp(0, OnboardingStep.values.length - 1);
    ref.listen(authSessionProvider, (previous, next) {
      if (previous?.id != next?.id) Future.microtask(refreshForSession);
    });
    if (user != null) Future.microtask(refreshForSession);
    return OnboardingState(
      introductionCompleted: _useCases.hasCompletedIntroduction(),
      userCompleted: false,
      isAuthenticated: user != null,
      draft: consumed
          ? const OnboardingProfileDraft()
          : _useCases.getDraft(user?.id),
      currentStep: OnboardingStep.values[resume],
      isResolvingSession: user != null,
    );
  }

  Future<void> refreshForSession({bool waitForRemote = true}) async {
    final user = ref.read(authSessionProvider);
    if (user == null) {
      state = state.copyWith(
        isAuthenticated: false,
        userCompleted: false,
        isResolvingSession: false,
        hasProfile: false,
        hasCurrentLegalConsent: false,
        resolutionFailed: false,
        introductionCompleted: _useCases.hasCompletedIntroduction(),
      );
      return;
    }
    final userId = user.id;
    state = state.copyWith(
      isAuthenticated: true,
      isResolvingSession: true,
      resolutionFailed: false,
      clearError: true,
    );
    try {
      await _useCases.claimPreAuthDraft(userId);
      if (waitForRemote) {
        await ref
            .read(syncBootstrapProvider)
            .waitForInitialSync(userId, cancelled: _disposed?.future);
      }
      if (!ref.mounted) return;
      if (ref.read(authSessionProvider)?.id != userId) return;
      final profile = await ref.read(profileUseCasesProvider).getProfile();
      final hasConsent = await ref
          .read(privacyUseCasesProvider)
          .hasCurrentConsent();
      if (profile != null && hasConsent) {
        await _useCases.completeForUser(userId);
        await _useCases.markDraftConsumed(userId);
        await _useCases.clearDraft(userId);
        state = state.copyWith(
          isAuthenticated: true,
          userCompleted: true,
          isResolvingSession: false,
          hasProfile: true,
          hasCurrentLegalConsent: true,
          resolutionFailed: false,
          currentStep: OnboardingStep.completion,
        );
        return;
      }

      final consumed = _useCases.hasConsumedDraft(userId);
      var draft = consumed
          ? const OnboardingProfileDraft()
          : _useCases.getDraft(userId);
      final settings = await ref.read(settingsUseCasesProvider).getSettings();
      draft = draft.copyWith(
        waterGoal: draft.waterGoal.isEmpty
            ? settings.dailyWaterGoalMl.toString()
            : draft.waterGoal,
        notificationsEnabled:
            settings.vitaminRemindersEnabled &&
            settings.medicationRemindersEnabled &&
            settings.appointmentRemindersEnabled,
      );
      final resume = _useCases
          .getResumeStep(userId)
          .clamp(
            OnboardingStep.initialData.index,
            OnboardingStep.documents.index,
          );
      state = state.copyWith(
        isAuthenticated: true,
        userCompleted: false,
        isResolvingSession: false,
        hasProfile: profile != null,
        hasCurrentLegalConsent: hasConsent,
        resolutionFailed: false,
        draft: draft.copyWith(
          termsAccepted: false,
          privacyPolicyAccepted: false,
        ),
        currentStep: profile != null && !hasConsent
            ? OnboardingStep.documents
            : OnboardingStep.values[resume],
      );
    } catch (error) {
      if (!ref.mounted) return;
      if (ref.read(authSessionProvider)?.id != userId) return;
      state = state.copyWith(
        isAuthenticated: true,
        userCompleted: false,
        isResolvingSession: false,
        resolutionFailed: true,
        errorMessage: PresentationErrorMapper.message(
          error,
          fallback:
              'Não foi possível restaurar seu onboarding. Tente novamente.',
        ),
      );
    }
  }

  Future<bool> next() async {
    if (state.isLastStep) return false;
    if (state.currentStep == OnboardingStep.documents) {
      try {
        _useCases.validateLegalAcceptance(state.draft);
      } catch (error) {
        state = state.copyWith(
          errorMessage: PresentationErrorMapper.message(
            error,
            fallback:
                'Aceite os Termos de Uso e a Política de Privacidade para continuar.',
          ),
        );
        return false;
      }
    }
    final step = OnboardingStep.values[state.currentIndex + 1];
    state = state.copyWith(currentStep: step);
    await _useCases.saveResumeStep(
      ref.read(authSessionProvider)?.id,
      step.index,
    );
    return true;
  }

  Future<void> previous() async {
    if (state.isFirstStep) return;
    final step = OnboardingStep.values[state.currentIndex - 1];
    state = state.copyWith(currentStep: step);
    await _useCases.saveResumeStep(
      ref.read(authSessionProvider)?.id,
      step.index,
    );
  }

  Future<void> skip() async {
    if (state.isAuthenticated) return;
    await _useCases.completeIntroduction();
    state = state.copyWith(introductionCompleted: true);
  }

  Future<bool> complete() async {
    final user = ref.read(authSessionProvider);
    if (user == null) {
      await _useCases.completeIntroduction();
      state = state.copyWith(introductionCompleted: true);
      return true;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      var draft = state.draft;
      if (draft.currentWeight.trim().isNotEmpty &&
          draft.currentWeightRecordId.isEmpty) {
        draft = draft.copyWith(
          currentWeightRecordId: ref.read(uuidServiceProvider).generate(),
        );
        await updateDraft(draft);
      }
      final result = await ref
          .read(onboardingCompletionServiceProvider)
          .complete(draft: draft, user: user);
      try {
        await ref
            .read(settingsReminderSyncServiceProvider)
            .applyAfterCommit(result.settings);
      } catch (_) {
        // Notification infrastructure cannot undo an offline local success.
      }

      await _useCases.completeForUser(user.id);
      await _useCases.markDraftConsumed(user.id);
      await _useCases.clearDraft(user.id);
      await _useCases.saveResumeStep(user.id, OnboardingStep.completion.index);
      _invalidateConsumers();
      unawaited(
        ref
            .read(syncManagerProvider.notifier)
            .syncNow()
            .catchError((_) => null),
      );
      state = state.copyWith(
        userCompleted: true,
        isSaving: false,
        hasProfile: true,
        hasCurrentLegalConsent: true,
        resolutionFailed: false,
        currentStep: OnboardingStep.completion,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: PresentationErrorMapper.message(
          error,
          fallback: 'Não foi possível concluir o onboarding. Tente novamente.',
        ),
      );
      return false;
    }
  }

  Future<void> updateDraft(OnboardingProfileDraft draft) async {
    state = state.copyWith(draft: draft, clearError: true);
    await _useCases.saveDraft(ref.read(authSessionProvider)?.id, draft);
  }

  Future<void> setNotificationsEnabled(bool value) => updateDraft(
    state.draft.copyWith(
      notificationsEnabled: value,
      notificationsConfirmed: false,
    ),
  );

  Future<void> toggleObjective(String objective) {
    final objectives = [...state.draft.objectives];
    objectives.contains(objective)
        ? objectives.remove(objective)
        : objectives.add(objective);
    return updateDraft(state.draft.copyWith(objectives: objectives));
  }

  void _invalidateConsumers() {
    ref.invalidate(profileUseCasesProvider);
    ref.invalidate(settingsUseCasesProvider);
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(profileViewModelProvider);
    ref.invalidate(settingsViewModelProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(waterViewModelProvider);
    ref.invalidate(weightUseCasesProvider);
    ref.invalidate(weightViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}

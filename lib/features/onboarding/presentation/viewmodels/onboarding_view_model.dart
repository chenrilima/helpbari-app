import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/bootstrap/sync_bootstrap_provider.dart';
import '../../../../core/errors/presentation_error_mapper.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/auth_user.dart';
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
  Future<void>? _activeRefresh;
  String? _activeRefreshUserId;
  int _sessionGeneration = 0;
  Future<bool>? _activeCompletion;

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
    final initial = OnboardingState(
      introductionCompleted: _useCases.hasCompletedIntroduction(),
      userCompleted: false,
      isAuthenticated: user != null,
      draft: consumed
          ? const OnboardingProfileDraft()
          : _useCases.getDraft(user?.id),
      currentStep: OnboardingStep.values[resume],
      isResolvingSession: user != null,
    );
    ref.listen<AuthUser?>(authSessionProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      _sessionGeneration++;
      _activeRefresh = null;
      _activeRefreshUserId = null;
      if (next == null) {
        _publish(
          state.copyWith(
            isAuthenticated: false,
            userCompleted: false,
            isResolvingSession: false,
            hasProfile: false,
            hasCurrentLegalConsent: false,
            requiresConsentReview: false,
            resolutionFailed: false,
            clearCanonicalProgress: true,
            introductionCompleted: _useCases.hasCompletedIntroduction(),
          ),
        );
      } else {
        unawaited(refreshForSession());
      }
    }, fireImmediately: true);
    return initial;
  }

  Future<void> refreshForSession({bool waitForRemote = true}) async {
    final user = ref.read(authSessionProvider);
    if (user == null) {
      _sessionGeneration++;
      _publish(
        state.copyWith(
          isAuthenticated: false,
          userCompleted: false,
          isResolvingSession: false,
          hasProfile: false,
          hasCurrentLegalConsent: false,
          resolutionFailed: false,
          requiresConsentReview: false,
          clearCanonicalProgress: true,
          introductionCompleted: _useCases.hasCompletedIntroduction(),
        ),
      );
      return;
    }
    final userId = user.id;
    if (_activeRefreshUserId == userId && _activeRefresh != null) {
      return _activeRefresh;
    }
    final generation = ++_sessionGeneration;
    final operation = _resolveSession(
      userId,
      generation: generation,
      waitForRemote: waitForRemote,
    );
    _activeRefreshUserId = userId;
    _activeRefresh = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeRefresh, operation)) {
        _activeRefresh = null;
        _activeRefreshUserId = null;
      }
    }
  }

  Future<void> _resolveSession(
    String userId, {
    required int generation,
    required bool waitForRemote,
  }) async {
    var localResolved = false;
    try {
      await _withSessionReadTimeout(_useCases.claimPreAuthDraft(userId));
      final service = await _withSessionReadTimeout(
        ref.read(onboardingProgressServiceProvider.future),
      );
      var progress = await _withSessionReadTimeout(service.resolve(userId));
      if (!_isCurrent(userId, generation)) return;
      localResolved = true;
      _publishProgress(userId, progress);
      await _enrichLocalState(userId, generation, progress);

      if (!waitForRemote || !_isCurrent(userId, generation)) return;
      try {
        await ref
            .read(syncBootstrapProvider)
            .waitForInitialSync(userId, cancelled: _disposed?.future);
        if (!_isCurrent(userId, generation)) return;
        progress = await _withSessionReadTimeout(service.resolve(userId));
        if (!_isCurrent(userId, generation)) return;
        _publishProgress(userId, progress);
        await _enrichLocalState(userId, generation, progress);
      } catch (_) {
        // Remote reconciliation is non-blocking after local resolution.
      }
    } catch (error) {
      if (!_isCurrent(userId, generation) || localResolved) return;
      _publish(
        state.copyWith(
          isAuthenticated: true,
          userCompleted: false,
          isResolvingSession: false,
          resolutionFailed: true,
          errorMessage: PresentationErrorMapper.message(
            error,
            fallback:
                'Não foi possível restaurar seu onboarding. Tente novamente.',
          ),
        ),
      );
    }
  }

  Future<void> _enrichLocalState(
    String userId,
    int generation,
    OnboardingProgress progress,
  ) async {
    try {
      final profile = await _withSessionReadTimeout(
        ref.read(profileUseCasesProvider).getProfile(),
      );
      final hasConsent = await _withSessionReadTimeout(
        ref.read(privacyUseCasesProvider).hasCurrentConsent(),
      );
      if (!_isCurrent(userId, generation)) return;
      if (progress.isCurrentCompleted) {
        await _useCases.completeForUser(userId);
        await _useCases.markDraftConsumed(userId);
        await _useCases.clearDraft(userId);
        _publish(
          state.copyWith(
            hasProfile: profile != null,
            hasCurrentLegalConsent: hasConsent,
            requiresConsentReview: !hasConsent,
          ),
        );
        return;
      }
      final consumed = _useCases.hasConsumedDraft(userId);
      var draft = consumed
          ? const OnboardingProfileDraft()
          : _useCases.getDraft(userId);
      final settings = await _withSessionReadTimeout(
        ref.read(settingsUseCasesProvider).getSettings(),
      );
      draft = draft.copyWith(
        waterGoal: draft.waterGoal.isEmpty
            ? settings.dailyWaterGoalMl.toString()
            : draft.waterGoal,
        notificationsEnabled:
            settings.vitaminRemindersEnabled &&
            settings.medicationRemindersEnabled &&
            settings.appointmentRemindersEnabled,
        termsAccepted: false,
        privacyPolicyAccepted: false,
      );
      final resume = _useCases
          .getResumeStep(userId)
          .clamp(
            OnboardingStep.initialData.index,
            OnboardingStep.documents.index,
          );
      _publish(
        state.copyWith(
          hasProfile: profile != null,
          hasCurrentLegalConsent: hasConsent,
          requiresConsentReview: false,
          draft: draft,
          currentStep: profile != null && !hasConsent
              ? OnboardingStep.documents
              : _stepForId(
                  progress.currentStepId,
                  OnboardingStep.values[resume],
                ),
        ),
      );
    } catch (_) {
      // A conclusão canônica local permanece válida mesmo se dados auxiliares
      // estiverem temporariamente indisponíveis.
    }
  }

  void _publishProgress(String userId, OnboardingProgress progress) {
    final completed = progress.isCurrentCompleted;
    _publish(
      state.copyWith(
        isAuthenticated: true,
        userCompleted: completed,
        isResolvingSession: false,
        resolutionFailed: false,
        clearError: true,
        currentStep: completed
            ? OnboardingStep.completion
            : _stepForId(progress.currentStepId, state.currentStep),
        canonicalProgress: progress,
      ),
    );
  }

  bool _isCurrent(String userId, int generation) =>
      ref.mounted &&
      generation == _sessionGeneration &&
      ref.read(authSessionProvider)?.id == userId;

  void _publish(OnboardingState next) {
    if (state != next) state = next;
  }

  Future<T> _withSessionReadTimeout<T>(Future<T> operation) {
    return operation.timeout(ref.read(onboardingSessionReadTimeoutProvider));
  }

  Future<bool> next() async {
    if (state.isLastStep) return false;
    if (state.currentStep == OnboardingStep.permissions &&
        !state.draft.notificationsConfirmed) {
      await updateDraft(state.draft.copyWith(notificationsConfirmed: true));
    }
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
    final progress = state.canonicalProgress;
    if (progress != null) {
      final service = await ref.read(onboardingProgressServiceProvider.future);
      state = state.copyWith(
        canonicalProgress: await service.saveStep(
          progress: progress,
          currentStepId: _stepId(step),
          completedStepId: _stepId(
            OnboardingStep.values[state.currentIndex - 1],
          ),
        ),
      );
    }
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
    final progress = state.canonicalProgress;
    if (progress != null) {
      final service = await ref.read(onboardingProgressServiceProvider.future);
      state = state.copyWith(
        canonicalProgress: await service.saveStep(
          progress: progress,
          currentStepId: _stepId(step),
        ),
      );
    }
  }

  Future<void> skip() async {
    if (state.isAuthenticated) return;
    await _useCases.completeIntroduction();
    state = state.copyWith(introductionCompleted: true);
  }

  Future<bool> complete() {
    if (state.userCompleted) return Future<bool>.value(true);
    final active = _activeCompletion;
    if (active != null) return active;
    final operation = _completeOnce();
    _activeCompletion = operation;
    operation.whenComplete(() {
      if (identical(_activeCompletion, operation)) _activeCompletion = null;
    });
    return operation;
  }

  Future<bool> _completeOnce() async {
    final user = ref.read(authSessionProvider);
    if (user == null) {
      await _useCases.completeIntroduction();
      state = state.copyWith(introductionCompleted: true);
      return true;
    }
    _publish(state.copyWith(isSaving: true, clearError: true));
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
      final currentProgress =
          state.canonicalProgress ??
          await (await ref.read(
            onboardingProgressServiceProvider.future,
          )).resolve(user.id);
      final completedProgress = await (await ref.read(
        onboardingProgressServiceProvider.future,
      )).complete(currentProgress);
      _invalidateConsumers();
      unawaited(
        ref
            .read(syncManagerProvider.notifier)
            .syncNow()
            .catchError((_) => null),
      );
      _publish(
        state.copyWith(
          userCompleted: true,
          isSaving: false,
          hasProfile: true,
          hasCurrentLegalConsent: true,
          resolutionFailed: false,
          currentStep: OnboardingStep.completion,
          canonicalProgress: completedProgress,
        ),
      );
      return true;
    } catch (error) {
      _publish(
        state.copyWith(
          isSaving: false,
          errorMessage: PresentationErrorMapper.message(
            error,
            fallback:
                'Não foi possível concluir o onboarding. Tente novamente.',
          ),
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
      notificationsConfirmed: true,
    ),
  );

  Future<void> toggleObjective(String objective) {
    final objectives = [...state.draft.objectives];
    objectives.contains(objective)
        ? objectives.remove(objective)
        : objectives.add(objective);
    return updateDraft(state.draft.copyWith(objectives: objectives));
  }

  Future<void> toggleTracking(String tracking) {
    final draft = state.draft;
    return updateDraft(switch (tracking) {
      'treatment' => draft.copyWith(trackTreatment: !draft.trackTreatment),
      'water' => draft.copyWith(trackWater: !draft.trackWater),
      'meals' => draft.copyWith(trackMeals: !draft.trackMeals),
      'weight' => draft.copyWith(trackWeight: !draft.trackWeight),
      _ => draft,
    });
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

  String _stepId(OnboardingStep step) => switch (step) {
    OnboardingStep.splash ||
    OnboardingStep.welcome ||
    OnboardingStep.benefits => 'welcome',
    OnboardingStep.permissions => 'reminderPreference',
    OnboardingStep.goals => 'trackingPreferences',
    OnboardingStep.initialData => 'basicProfile',
    OnboardingStep.documents => 'legalConsents',
    OnboardingStep.completion => 'completion',
  };

  OnboardingStep _stepForId(String? id, OnboardingStep fallback) =>
      switch (id) {
        'welcome' => OnboardingStep.welcome,
        'reminderPreference' => OnboardingStep.permissions,
        'trackingPreferences' ||
        'trackingConfiguration' => OnboardingStep.goals,
        'basicProfile' ||
        'bariatricJourney' ||
        'weightAndGoals' => OnboardingStep.initialData,
        'legalConsents' => OnboardingStep.documents,
        'completion' => OnboardingStep.completion,
        _ => fallback,
      };
}

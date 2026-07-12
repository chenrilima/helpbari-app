import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../profile/domain/value_objects/value_objects.dart';
import '../../../privacy/presentation/providers/privacy_providers.dart';
import '../../../profile/presentation/models/create_profile_form.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../profile/presentation/providers/profile_view_model_provider.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../settings/presentation/providers/setting_view_model_provider.dart';
import '../../../settings/presentation/providers/settings_reminder_sync_provider.dart';
import '../../../water/presentation/providers/water_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/onboarding_providers.dart';
import '../states/onboarding_state.dart';

class OnboardingViewModel extends Notifier<OnboardingState> {
  OnboardingUseCases get _useCases => ref.read(onboardingUseCasesProvider);

  @override
  OnboardingState build() {
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
      userCompleted: user != null && _useCases.hasCompletedForUser(user.id),
      isAuthenticated: user != null,
      draft: consumed ? const OnboardingProfileDraft() : _useCases.getDraft(),
      currentStep: OnboardingStep.values[resume],
    );
  }

  Future<void> refreshForSession() async {
    final user = ref.read(authSessionProvider);
    if (user == null) {
      state = state.copyWith(
        isAuthenticated: false,
        userCompleted: false,
        introductionCompleted: _useCases.hasCompletedIntroduction(),
      );
      return;
    }
    var completed = _useCases.hasCompletedForUser(user.id);
    var hasConsent = false;
    try {
      hasConsent = await ref.read(privacyUseCasesProvider).hasCurrentConsent();
    } catch (_) {
      // Mandatory acceptance remains pending when local data is unavailable.
    }
    if (completed && !hasConsent) {
      completed = false;
      state = state.copyWith(
        isAuthenticated: true,
        userCompleted: false,
        draft: state.draft.copyWith(documentsAccepted: false),
        currentStep: OnboardingStep.documents,
      );
      return;
    }
    if (!completed) {
      try {
        final profile = await ref.read(profileUseCasesProvider).getProfile();
        if (profile != null && hasConsent) {
          await _useCases.completeForUser(user.id);
          await _useCases.markDraftConsumed(user.id);
          state = state.copyWith(
            isAuthenticated: true,
            userCompleted: true,
            currentStep: OnboardingStep.completion,
          );
          return;
        }
      } catch (_) {
        // Offline/temporary database errors must not manufacture completion.
      }
    }
    final consumed = _useCases.hasConsumedDraft(user.id);
    var draft = consumed
        ? const OnboardingProfileDraft()
        : _useCases.getDraft();
    try {
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
    } catch (_) {
      // Existing Settings are optional prefill and still require confirmation.
    }
    final resume = _useCases
        .getResumeStep(user.id)
        .clamp(
          OnboardingStep.initialData.index,
          OnboardingStep.completion.index,
        );
    state = state.copyWith(
      isAuthenticated: true,
      userCompleted: completed,
      draft: draft,
      currentStep: OnboardingStep.values[resume],
    );
  }

  Future<void> next() async {
    if (state.isLastStep) return;
    final step = OnboardingStep.values[state.currentIndex + 1];
    state = state.copyWith(currentStep: step);
    await _useCases.saveResumeStep(
      ref.read(authSessionProvider)?.id,
      step.index,
    );
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
      if (!state.draft.documentsAccepted) {
        throw const FormatException(
          'Aceite os Termos de Uso e a Política de Privacidade.',
        );
      }
      await ref.read(privacyUseCasesProvider).acceptCurrentDocuments();
      final existingProfile = await ref
          .read(profileUseCasesProvider)
          .getProfile();
      if (existingProfile == null) {
        final form = _validatedForm(state.draft, user.email ?? '');
        await ref.read(profileViewModelProvider.notifier).loadProfile();
        await ref.read(profileViewModelProvider.notifier).saveProfile(form);
        final profileState = ref.read(profileViewModelProvider);
        if (profileState.profile == null || profileState.errorMessage != null) {
          throw StateError(
            profileState.errorMessage ?? 'Perfil não foi salvo.',
          );
        }

        final settingsUseCases = ref.read(settingsUseCasesProvider);
        final current = await settingsUseCases.getSettings();
        var confirmed = current;
        if (state.draft.waterGoalConfirmed) {
          confirmed = confirmed.copyWith(
            dailyWaterGoalMl: int.parse(state.draft.waterGoal),
          );
        }
        if (state.draft.notificationsConfirmed) {
          confirmed = confirmed.copyWith(
            vitaminRemindersEnabled: state.draft.notificationsEnabled,
            medicationRemindersEnabled: state.draft.notificationsEnabled,
            appointmentRemindersEnabled: state.draft.notificationsEnabled,
          );
        }
        await settingsUseCases.saveSettings(confirmed);
        try {
          await ref
              .read(settingsReminderSyncServiceProvider)
              .applyAfterCommit(confirmed);
        } catch (_) {
          // Notification infrastructure cannot undo an offline local success.
        }
      }

      await _useCases.completeForUser(user.id);
      await _useCases.markDraftConsumed(user.id);
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
        currentStep: OnboardingStep.completion,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
      return false;
    }
  }

  CreateProfileForm _validatedForm(OnboardingProfileDraft draft, String email) {
    final birthDate = _parseDate(draft.birthDate);
    final surgeryDate = _parseDate(draft.surgeryDate);
    final height = int.tryParse(draft.height.trim());
    final explicitInitial = double.tryParse(
      draft.initialWeight.trim().replaceAll(',', '.'),
    );
    final current = double.tryParse(
      draft.currentWeight.trim().replaceAll(',', '.'),
    );
    final initial =
        explicitInitial ??
        (draft.currentWeightConfirmedAsInitial ? current : null);
    final target = draft.targetWeight.trim().isEmpty
        ? null
        : double.tryParse(draft.targetWeight.trim().replaceAll(',', '.'));
    final surgeryType = SurgeryType.values.firstWhere(
      (value) => value.name == draft.surgeryType,
      orElse: () => SurgeryType.other,
    );
    final goal = int.tryParse(draft.waterGoal.trim());
    if (draft.name.trim().length < 2 ||
        email.isEmpty ||
        birthDate == null ||
        surgeryDate == null ||
        height == null ||
        Height.create(height) == null ||
        initial == null ||
        Weight.create(initial) == null ||
        (target != null && Weight.create(target) == null)) {
      throw const FormatException('Revise os campos obrigatórios do perfil.');
    }
    if (!draft.waterGoalConfirmed ||
        goal == null ||
        goal < 500 ||
        goal > 6000) {
      throw const FormatException(
        'Confirme uma meta de água entre 500 e 6000 ml.',
      );
    }
    if (!draft.notificationsConfirmed) {
      throw const FormatException('Confirme sua escolha de notificações.');
    }
    return CreateProfileForm(
      name: draft.name.trim(),
      email: email,
      birthDate: birthDate,
      height: height,
      initialWeight: initial,
      targetWeight: target,
      surgeryDate: surgeryDate,
      surgeryType: surgeryType,
    );
  }

  DateTime? _parseDate(String raw) {
    final parts = raw.trim().split('/');
    if (parts.length != 3) return DateTime.tryParse(raw.trim());
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final value = DateTime(year, month, day);
    return value.day == day && value.month == month && value.year == year
        ? value
        : null;
  }

  Future<void> updateDraft(OnboardingProfileDraft draft) async {
    state = state.copyWith(draft: draft, clearError: true);
    await _useCases.saveDraft(draft);
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
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(waterViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
  }
}

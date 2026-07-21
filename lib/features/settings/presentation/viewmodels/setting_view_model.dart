import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../providers/settings_reminder_sync_provider.dart';
import '../providers/setting_use_cases_provider.dart';
import '../states/setting_state.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';
import '../../domain/entities/entities.dart';
import '../../../../app/bootstrap/notification_bootstrap_provider.dart';

class SettingsViewModel extends Notifier<SettingsState> {
  bool _isMutating = false;

  @override
  SettingsState build() {
    return const SettingsState();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final settings = await ref.read(settingsUseCasesProvider).getSettings();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> updateDailyWaterGoal(int goalMl) async {
    await _mutate(
      () => ref.read(settingsUseCasesProvider).updateDailyWaterGoal(goalMl),
    );
  }

  Future<void> toggleVitaminReminders(bool enabled) async {
    await _mutate(
      () => ref.read(settingsUseCasesProvider).toggleVitaminReminders(enabled),
    );
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    await _mutate(
      () =>
          ref.read(settingsUseCasesProvider).toggleMedicationReminders(enabled),
    );
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    await _mutate(
      () => ref
          .read(settingsUseCasesProvider)
          .toggleAppointmentReminders(enabled),
    );
  }

  Future<void> toggleMealTracking(bool enabled) async {
    await _mutate(
      () => ref.read(settingsUseCasesProvider).toggleMealTracking(enabled),
    );
  }

  Future<void> setGlobalNotifications(bool enabled) => _mutate(
    () => ref.read(settingsUseCasesProvider).setGlobalNotifications(enabled),
  );

  Future<void> setNotificationCategory(
    NotificationCategory category,
    bool enabled,
  ) => _mutate(
    () => ref
        .read(settingsUseCasesProvider)
        .setNotificationCategory(category, enabled),
  );

  Future<void> putNotificationTime(NotificationTimePreference preference) =>
      _mutate(
        () =>
            ref.read(settingsUseCasesProvider).putNotificationTime(preference),
      );

  Future<void> updateTrackingPreferences({
    required bool treatment,
    required bool water,
    required bool meals,
    required bool weight,
  }) async {
    await _mutate(
      () => ref
          .read(settingsUseCasesProvider)
          .updateTrackingPreferences(
            treatment: treatment,
            water: water,
            meals: meals,
            weight: weight,
          ),
    );
  }

  Future<void> _mutate(Future<void> Function() persistLocally) async {
    if (_isMutating) return;
    _isMutating = true;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await persistLocally();
      _invalidateConsumers();
      await loadSettings();
      _invalidateConsumers();
      try {
        final settings = await ref.read(settingsUseCasesProvider).getSettings();
        await ref
            .read(settingsReminderSyncServiceProvider)
            .applyAfterCommit(settings);
        ref.read(notificationBootstrapProvider).restoreAfterSync();
      } catch (error) {
        ref
            .read(loggerServiceProvider)
            .warning(
              'Notification settings reconciliation failed (${error.runtimeType}).',
            );
      }

      // Drift is already committed. Network work must not change local success.
      unawaited(
        ref
            .read(syncManagerProvider.notifier)
            .syncNow()
            .catchError((_) => null),
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    } finally {
      _isMutating = false;
      state = state.copyWith(isSaving: false);
    }
  }

  void _invalidateConsumers() {
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(todayDashboardProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
  }
}

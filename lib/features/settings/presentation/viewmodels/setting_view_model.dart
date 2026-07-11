import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../providers/settings_reminder_sync_provider.dart';
import '../providers/setting_use_cases_provider.dart';
import '../states/setting_state.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';

class SettingsViewModel extends Notifier<SettingsState> {
  bool _isMutating = false;

  @override
  SettingsState build() {
    return const SettingsState();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);

    final settings = await ref.read(settingsUseCasesProvider).getSettings();

    state = state.copyWith(settings: settings, isLoading: false);
  }

  Future<void> updateDailyWaterGoal(int goalMl) async {
    await _mutate(
      () => ref.read(settingsUseCasesProvider).updateDailyWaterGoal(goalMl),
    );
  }

  Future<void> toggleVitaminReminders(bool enabled) async {
    await _mutate(() async {
      await ref.read(settingsUseCasesProvider).toggleVitaminReminders(enabled);
      await ref
          .read(settingsReminderSyncServiceProvider)
          .syncVitaminReminders(enabled);
    });
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    await _mutate(() async {
      await ref
          .read(settingsUseCasesProvider)
          .toggleMedicationReminders(enabled);
      await ref
          .read(settingsReminderSyncServiceProvider)
          .syncMedicationReminders(enabled);
    });
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    await _mutate(() async {
      await ref
          .read(settingsUseCasesProvider)
          .toggleAppointmentReminders(enabled);
      await ref
          .read(settingsReminderSyncServiceProvider)
          .syncAppointmentReminders(enabled);
    });
  }

  Future<void> toggleMealTracking(bool enabled) async {
    await _mutate(
      () => ref.read(settingsUseCasesProvider).toggleMealTracking(enabled),
    );
  }

  Future<void> _mutate(Future<void> Function() persistLocally) async {
    if (_isMutating) return;
    _isMutating = true;
    try {
      await persistLocally();
      _invalidateConsumers();
      await loadSettings();
      _invalidateConsumers();

      // Drift is already committed. Network work must not change local success.
      unawaited(
        ref
            .read(syncManagerProvider.notifier)
            .syncNow()
            .catchError((_) => null),
      );
    } finally {
      _isMutating = false;
    }
  }

  void _invalidateConsumers() {
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
  }
}

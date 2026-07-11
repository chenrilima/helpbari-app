import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_reminder_sync_provider.dart';
import '../providers/setting_use_cases_provider.dart';
import '../states/setting_state.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../charts/presentation/providers/chart_series_providers.dart';
import '../../../medical_reports/presentation/providers/medical_report_providers.dart';

class SettingsViewModel extends Notifier<SettingsState> {
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
    await ref.read(settingsUseCasesProvider).updateDailyWaterGoal(goalMl);
    ref.invalidate(dailyWaterGoalProvider);
    _invalidateConsumers();
    await loadSettings();
    _invalidateConsumers();
  }

  Future<void> toggleVitaminReminders(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleVitaminReminders(enabled);
    await ref
        .read(settingsReminderSyncServiceProvider)
        .syncVitaminReminders(enabled);
    await loadSettings();
    _invalidateConsumers();
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleMedicationReminders(enabled);
    await ref
        .read(settingsReminderSyncServiceProvider)
        .syncMedicationReminders(enabled);
    await loadSettings();
    _invalidateConsumers();
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    await ref
        .read(settingsUseCasesProvider)
        .toggleAppointmentReminders(enabled);
    await ref
        .read(settingsReminderSyncServiceProvider)
        .syncAppointmentReminders(enabled);
    await loadSettings();
  }

  Future<void> toggleMealTracking(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleMealTracking(enabled);
    await loadSettings();
    _invalidateConsumers();
  }

  void _invalidateConsumers() {
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
  }
}

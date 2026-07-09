import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_reminder_sync_provider.dart';
import '../providers/setting_use_cases_provider.dart';
import '../states/setting_state.dart';

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
    await loadSettings();
  }

  Future<void> toggleVitaminReminders(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleVitaminReminders(enabled);
    await ref
        .read(settingsReminderSyncServiceProvider)
        .syncVitaminReminders(enabled);
    await loadSettings();
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleMedicationReminders(enabled);
    await ref
        .read(settingsReminderSyncServiceProvider)
        .syncMedicationReminders(enabled);
    await loadSettings();
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
  }
}

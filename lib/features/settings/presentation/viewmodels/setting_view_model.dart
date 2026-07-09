import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
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
    await _syncVitaminReminders(enabled);
    await loadSettings();
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleMedicationReminders(enabled);
    await _syncMedicationReminders(enabled);
    await loadSettings();
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    await ref
        .read(settingsUseCasesProvider)
        .toggleAppointmentReminders(enabled);
    await _syncAppointmentReminders(enabled);
    await loadSettings();
  }

  Future<void> toggleMealTracking(bool enabled) async {
    await ref.read(settingsUseCasesProvider).toggleMealTracking(enabled);
    await loadSettings();
  }

  Future<void> _syncVitaminReminders(bool enabled) async {
    final notifications = ref.read(localNotificationServiceProvider);
    final vitamins = await ref.read(vitaminUseCasesProvider).getAll();

    if (!enabled) {
      for (final vitamin in vitamins) {
        await notifications.cancelPayload(
          LocalNotificationPayload(
            source: NotificationSource.vitamin,
            entityId: vitamin.id,
          ),
        );
      }

      return;
    }

    await notifications.reschedule(vitamins.map(NotificationSchedules.vitamin));
  }

  Future<void> _syncMedicationReminders(bool enabled) async {
    final notifications = ref.read(localNotificationServiceProvider);
    final medications = await ref.read(medicationUseCasesProvider).getAll();

    if (!enabled) {
      for (final medication in medications) {
        await notifications.cancelPayload(
          LocalNotificationPayload(
            source: NotificationSource.medication,
            entityId: medication.id,
          ),
        );
      }

      return;
    }

    await notifications.reschedule(
      medications.map(NotificationSchedules.medication),
    );
  }

  Future<void> _syncAppointmentReminders(bool enabled) async {
    final notifications = ref.read(localNotificationServiceProvider);
    final appointments = await ref.read(appointmentUseCasesProvider).getAll();

    if (!enabled) {
      for (final appointment in appointments) {
        await notifications.cancelPayload(
          LocalNotificationPayload(
            source: NotificationSource.appointment,
            entityId: appointment.id,
          ),
        );
      }

      return;
    }

    await notifications.reschedule(
      appointments
          .where((appointment) => appointment.isUpcoming)
          .map(NotificationSchedules.appointment),
    );
  }
}

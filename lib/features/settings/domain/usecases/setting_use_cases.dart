import '../entities/entities.dart';
import '../repositories/repositories.dart';

class SettingsUseCases {
  const SettingsUseCases(this._repository);

  final SettingsRepository _repository;

  Future<AppSettings> getSettings() {
    return _repository.getSettings();
  }

  Future<void> saveSettings(AppSettings settings) {
    return _repository.saveSettings(settings);
  }

  Future<void> updateDailyWaterGoal(int goalMl) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(current.copyWith(dailyWaterGoalMl: goalMl));
  }

  Future<void> toggleVitaminReminders(bool enabled) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(
      current.copyWith(vitaminRemindersEnabled: enabled),
    );
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(
      current.copyWith(medicationRemindersEnabled: enabled),
    );
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(
      current.copyWith(appointmentRemindersEnabled: enabled),
    );
  }

  Future<void> toggleMealTracking(bool enabled) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(
      current.copyWith(mealTrackingEnabled: enabled),
    );
  }
}

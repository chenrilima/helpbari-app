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
    final preferences = current.effectiveNotificationPreferences.setCategory(
      NotificationCategory.treatment,
      enabled || current.medicationRemindersEnabled,
    );
    await _saveNotificationPreferences(current, preferences);
  }

  Future<void> toggleMedicationReminders(bool enabled) async {
    final current = await _repository.getSettings();

    final preferences = current.effectiveNotificationPreferences.setCategory(
      NotificationCategory.treatment,
      enabled || current.vitaminRemindersEnabled,
    );
    await _saveNotificationPreferences(current, preferences);
  }

  Future<void> toggleAppointmentReminders(bool enabled) async {
    final current = await _repository.getSettings();

    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.setCategory(
        NotificationCategory.appointments,
        enabled,
      ),
    );
  }

  Future<void> setGlobalNotifications(bool enabled) async {
    final current = await _repository.getSettings();
    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.copyWith(globalEnabled: enabled),
    );
  }

  Future<void> setNotificationCategory(
    NotificationCategory category,
    bool enabled,
  ) async {
    final current = await _repository.getSettings();
    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.setCategory(category, enabled),
    );
  }

  Future<void> setNotificationItem({
    required NotificationCategory category,
    required String itemId,
    required bool enabled,
  }) async {
    final current = await _repository.getSettings();
    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.setItem(
        category,
        itemId,
        enabled,
      ),
    );
  }

  Future<void> putNotificationTime(
    NotificationTimePreference preference,
  ) async {
    final current = await _repository.getSettings();
    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.putTime(preference),
    );
  }

  Future<void> removeNotificationTime(String id) async {
    final current = await _repository.getSettings();
    await _saveNotificationPreferences(
      current,
      current.effectiveNotificationPreferences.removeTime(id),
    );
  }

  Future<void> _saveNotificationPreferences(
    AppSettings current,
    NotificationPreferences preferences,
  ) => _repository.saveSettings(
    current.copyWith(
      notificationPreferences: preferences,
      vitaminRemindersEnabled: preferences.categoryEnabled(
        NotificationCategory.treatment,
      ),
      medicationRemindersEnabled: preferences.categoryEnabled(
        NotificationCategory.treatment,
      ),
      appointmentRemindersEnabled: preferences.categoryEnabled(
        NotificationCategory.appointments,
      ),
    ),
  );

  Future<void> toggleMealTracking(bool enabled) async {
    final current = await _repository.getSettings();

    await _repository.saveSettings(
      current.copyWith(mealTrackingEnabled: enabled),
    );
  }

  Future<void> updateTrackingPreferences({
    required bool treatment,
    required bool water,
    required bool meals,
    required bool weight,
  }) async {
    final current = await _repository.getSettings();
    await _repository.saveSettings(
      current.copyWith(
        treatmentTrackingEnabled: treatment,
        waterTrackingEnabled: water,
        mealTrackingEnabled: meals,
        weightTrackingEnabled: weight,
      ),
    );
  }
}

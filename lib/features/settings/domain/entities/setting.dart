import '../../../../core/domain/entity.dart';
import 'notification_preferences.dart';

class AppSettings extends Entity {
  const AppSettings({
    required this.id,
    this.dailyWaterGoalMl = 2000,
    this.vitaminRemindersEnabled = true,
    this.medicationRemindersEnabled = true,
    this.appointmentRemindersEnabled = true,
    this.mealTrackingEnabled = true,
    this.treatmentTrackingEnabled = true,
    this.waterTrackingEnabled = true,
    this.weightTrackingEnabled = true,
    this.weightUnit = 'kg',
    this.notificationPreferences,
  });

  @override
  final String id;

  final int dailyWaterGoalMl;
  final bool vitaminRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool mealTrackingEnabled;
  final bool treatmentTrackingEnabled;
  final bool waterTrackingEnabled;
  final bool weightTrackingEnabled;
  final String weightUnit;
  final NotificationPreferences? notificationPreferences;

  NotificationPreferences get effectiveNotificationPreferences =>
      notificationPreferences ??
      NotificationPreferences.legacy(
        vitamins: vitaminRemindersEnabled,
        medications: medicationRemindersEnabled,
        appointments: appointmentRemindersEnabled,
      );

  AppSettings copyWith({
    int? dailyWaterGoalMl,
    bool? vitaminRemindersEnabled,
    bool? medicationRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? mealTrackingEnabled,
    bool? treatmentTrackingEnabled,
    bool? waterTrackingEnabled,
    bool? weightTrackingEnabled,
    String? weightUnit,
    NotificationPreferences? notificationPreferences,
  }) {
    return AppSettings(
      id: id,
      dailyWaterGoalMl: dailyWaterGoalMl ?? this.dailyWaterGoalMl,
      vitaminRemindersEnabled:
          vitaminRemindersEnabled ?? this.vitaminRemindersEnabled,
      medicationRemindersEnabled:
          medicationRemindersEnabled ?? this.medicationRemindersEnabled,
      appointmentRemindersEnabled:
          appointmentRemindersEnabled ?? this.appointmentRemindersEnabled,
      mealTrackingEnabled: mealTrackingEnabled ?? this.mealTrackingEnabled,
      treatmentTrackingEnabled:
          treatmentTrackingEnabled ?? this.treatmentTrackingEnabled,
      waterTrackingEnabled: waterTrackingEnabled ?? this.waterTrackingEnabled,
      weightTrackingEnabled:
          weightTrackingEnabled ?? this.weightTrackingEnabled,
      weightUnit: weightUnit ?? this.weightUnit,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }
}

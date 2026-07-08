import '../../../../core/domain/entity.dart';

class AppSettings extends Entity {
  const AppSettings({
    required this.id,
    this.dailyWaterGoalMl = 2000,
    this.vitaminRemindersEnabled = true,
    this.medicationRemindersEnabled = true,
    this.appointmentRemindersEnabled = true,
    this.mealTrackingEnabled = true,
    this.weightUnit = 'kg',
  });

  @override
  final String id;

  final int dailyWaterGoalMl;
  final bool vitaminRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool mealTrackingEnabled;
  final String weightUnit;

  AppSettings copyWith({
    int? dailyWaterGoalMl,
    bool? vitaminRemindersEnabled,
    bool? medicationRemindersEnabled,
    bool? appointmentRemindersEnabled,
    bool? mealTrackingEnabled,
    String? weightUnit,
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
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }
}

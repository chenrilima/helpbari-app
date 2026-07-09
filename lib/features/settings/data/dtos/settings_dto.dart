import '../../../../core/database/database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';

class SettingsDto {
  const SettingsDto({
    required this.id,
    required this.dailyWaterGoalMl,
    required this.vitaminRemindersEnabled,
    required this.medicationRemindersEnabled,
    required this.appointmentRemindersEnabled,
    required this.mealTrackingEnabled,
    required this.weightUnit,
    required this.syncMetadata,
  });

  final String id;
  final int dailyWaterGoalMl;
  final bool vitaminRemindersEnabled;
  final bool medicationRemindersEnabled;
  final bool appointmentRemindersEnabled;
  final bool mealTrackingEnabled;
  final String weightUnit;
  final SyncMetadata syncMetadata;

  AppSettings toEntity() {
    return AppSettings(
      id: id,
      dailyWaterGoalMl: dailyWaterGoalMl,
      vitaminRemindersEnabled: vitaminRemindersEnabled,
      medicationRemindersEnabled: medicationRemindersEnabled,
      appointmentRemindersEnabled: appointmentRemindersEnabled,
      mealTrackingEnabled: mealTrackingEnabled,
      weightUnit: weightUnit,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'dailyWaterGoalMl': dailyWaterGoalMl,
        'vitaminRemindersEnabled': vitaminRemindersEnabled,
        'medicationRemindersEnabled': medicationRemindersEnabled,
        'appointmentRemindersEnabled': appointmentRemindersEnabled,
        'mealTrackingEnabled': mealTrackingEnabled,
        'weightUnit': weightUnit,
      },
    );
  }

  static SettingsDto fromEntity(
    AppSettings settings, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return SettingsDto(
      id: settings.id,
      dailyWaterGoalMl: settings.dailyWaterGoalMl,
      vitaminRemindersEnabled: settings.vitaminRemindersEnabled,
      medicationRemindersEnabled: settings.medicationRemindersEnabled,
      appointmentRemindersEnabled: settings.appointmentRemindersEnabled,
      mealTrackingEnabled: settings.mealTrackingEnabled,
      weightUnit: settings.weightUnit,
      syncMetadata: SyncMetadata(
        id: settings.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static SettingsDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return SettingsDto(
      id: record.id,
      dailyWaterGoalMl: data['dailyWaterGoalMl'] as int,
      vitaminRemindersEnabled: data['vitaminRemindersEnabled'] as bool,
      medicationRemindersEnabled: data['medicationRemindersEnabled'] as bool,
      appointmentRemindersEnabled: data['appointmentRemindersEnabled'] as bool,
      mealTrackingEnabled: data['mealTrackingEnabled'] as bool,
      weightUnit: data['weightUnit'] as String,
      syncMetadata: record.metadata,
    );
  }

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) {
    return switch (currentStatus) {
      SyncStatus.synced => SyncStatus.pendingUpdate,
      SyncStatus.failed => SyncStatus.pendingUpdate,
      SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
      SyncStatus.pendingCreate => SyncStatus.pendingCreate,
      SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
      null => SyncStatus.pendingCreate,
    };
  }
}

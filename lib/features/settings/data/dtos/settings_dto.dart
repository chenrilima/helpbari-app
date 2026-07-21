import 'dart:convert';

import '../../../../core/database/database.dart';
import '../../../../core/database/drift/app_database.dart';
import 'package:drift/drift.dart' show Value;
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
    required this.treatmentTrackingEnabled,
    required this.waterTrackingEnabled,
    required this.weightTrackingEnabled,
    required this.weightUnit,
    required this.syncMetadata,
    this.notificationPreferencesJson = '',
  });

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
  final SyncMetadata syncMetadata;
  final String notificationPreferencesJson;

  AppSettings toEntity() {
    final decoded = _decodePreferences(notificationPreferencesJson);
    return AppSettings(
      id: id,
      dailyWaterGoalMl: dailyWaterGoalMl,
      vitaminRemindersEnabled: vitaminRemindersEnabled,
      medicationRemindersEnabled: medicationRemindersEnabled,
      appointmentRemindersEnabled: appointmentRemindersEnabled,
      mealTrackingEnabled: mealTrackingEnabled,
      treatmentTrackingEnabled: treatmentTrackingEnabled,
      waterTrackingEnabled: waterTrackingEnabled,
      weightTrackingEnabled: weightTrackingEnabled,
      weightUnit: weightUnit,
      notificationPreferences:
          NotificationPreferences.fromJson(decoded) ??
          NotificationPreferences.legacy(
            vitamins: vitaminRemindersEnabled,
            medications: medicationRemindersEnabled,
            appointments: appointmentRemindersEnabled,
          ),
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
        'treatmentTrackingEnabled': treatmentTrackingEnabled,
        'waterTrackingEnabled': waterTrackingEnabled,
        'weightTrackingEnabled': weightTrackingEnabled,
        'weightUnit': weightUnit,
        'notificationPreferencesJson': notificationPreferencesJson,
      },
    );
  }

  static SettingsDto fromEntity(
    AppSettings settings, {
    required DateTime now,
    SyncMetadata? previousMetadata,
    String? userId,
  }) {
    return SettingsDto(
      id: settings.id,
      dailyWaterGoalMl: settings.dailyWaterGoalMl,
      vitaminRemindersEnabled: settings.vitaminRemindersEnabled,
      medicationRemindersEnabled: settings.medicationRemindersEnabled,
      appointmentRemindersEnabled: settings.appointmentRemindersEnabled,
      mealTrackingEnabled: settings.mealTrackingEnabled,
      treatmentTrackingEnabled: settings.treatmentTrackingEnabled,
      waterTrackingEnabled: settings.waterTrackingEnabled,
      weightTrackingEnabled: settings.weightTrackingEnabled,
      weightUnit: settings.weightUnit,
      notificationPreferencesJson: jsonEncode(
        settings.effectiveNotificationPreferences.toJson(),
      ),
      syncMetadata: SyncMetadata(
        id: settings.id,
        userId: previousMetadata?.userId ?? userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static SettingsDto fromDrift(SettingsRecord row) => SettingsDto(
    id: row.id,
    dailyWaterGoalMl: row.dailyWaterGoalMl,
    vitaminRemindersEnabled: row.vitaminRemindersEnabled,
    medicationRemindersEnabled: row.medicationRemindersEnabled,
    appointmentRemindersEnabled: row.appointmentRemindersEnabled,
    mealTrackingEnabled: row.mealTrackingEnabled,
    treatmentTrackingEnabled: row.treatmentTrackingEnabled,
    waterTrackingEnabled: row.waterTrackingEnabled,
    weightTrackingEnabled: row.weightTrackingEnabled,
    weightUnit: row.weightUnit,
    notificationPreferencesJson: row.notificationPreferencesJson,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );

  SettingsRecordsCompanion toDrift({required String userId}) =>
      SettingsRecordsCompanion.insert(
        id: id,
        userId: userId,
        dailyWaterGoalMl: Value(dailyWaterGoalMl),
        vitaminRemindersEnabled: Value(vitaminRemindersEnabled),
        medicationRemindersEnabled: Value(medicationRemindersEnabled),
        appointmentRemindersEnabled: Value(appointmentRemindersEnabled),
        mealTrackingEnabled: Value(mealTrackingEnabled),
        treatmentTrackingEnabled: Value(treatmentTrackingEnabled),
        waterTrackingEnabled: Value(waterTrackingEnabled),
        weightTrackingEnabled: Value(weightTrackingEnabled),
        weightUnit: Value(weightUnit),
        notificationPreferencesJson: Value(notificationPreferencesJson),
        createdAt: syncMetadata.createdAt,
        updatedAt: syncMetadata.updatedAt,
        deletedAt: Value(syncMetadata.deletedAt),
        syncStatus: syncMetadata.syncStatus.name,
      );

  Map<String, Object?> toSupabase(String userId) => {
    'id': id,
    'user_id': userId,
    'daily_water_goal_ml': dailyWaterGoalMl,
    'vitamin_reminders_enabled': vitaminRemindersEnabled,
    'medication_reminders_enabled': medicationRemindersEnabled,
    'appointment_reminders_enabled': appointmentRemindersEnabled,
    'meal_tracking_enabled': mealTrackingEnabled,
    'treatment_tracking_enabled': treatmentTrackingEnabled,
    'water_tracking_enabled': waterTrackingEnabled,
    'weight_tracking_enabled': weightTrackingEnabled,
    'weight_unit': weightUnit,
    'notification_preferences': _decodePreferences(notificationPreferencesJson),
    'created_at': syncMetadata.createdAt.toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toIso8601String(),
  };

  static SettingsDto fromSupabase(Map<String, dynamic> row) {
    DateTime date(String key) => DateTime.parse(row[key] as String);
    return SettingsDto(
      id: row['id'] as String,
      dailyWaterGoalMl: row['daily_water_goal_ml'] as int,
      vitaminRemindersEnabled: row['vitamin_reminders_enabled'] as bool,
      medicationRemindersEnabled: row['medication_reminders_enabled'] as bool,
      appointmentRemindersEnabled: row['appointment_reminders_enabled'] as bool,
      mealTrackingEnabled: row['meal_tracking_enabled'] as bool,
      treatmentTrackingEnabled:
          row['treatment_tracking_enabled'] as bool? ?? true,
      waterTrackingEnabled: row['water_tracking_enabled'] as bool? ?? true,
      weightTrackingEnabled: row['weight_tracking_enabled'] as bool? ?? true,
      weightUnit: row['weight_unit'] as String,
      notificationPreferencesJson: jsonEncode(
        row['notification_preferences'] ?? const <String, Object?>{},
      ),
      syncMetadata: SyncMetadata(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        createdAt: date('created_at'),
        updatedAt: date('updated_at'),
        deletedAt: row['deleted_at'] == null ? null : date('deleted_at'),
        syncStatus: SyncStatus.synced,
        serverRevision: row['server_revision'] as int?,
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
      treatmentTrackingEnabled:
          data['treatmentTrackingEnabled'] as bool? ?? true,
      waterTrackingEnabled: data['waterTrackingEnabled'] as bool? ?? true,
      weightTrackingEnabled: data['weightTrackingEnabled'] as bool? ?? true,
      weightUnit: data['weightUnit'] as String,
      notificationPreferencesJson:
          data['notificationPreferencesJson'] as String? ?? '',
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

  static Object _decodePreferences(String encoded) {
    if (encoded.isEmpty) return const <String, Object?>{};
    try {
      return jsonDecode(encoded) ?? const <String, Object?>{};
    } on FormatException {
      return const <String, Object?>{};
    }
  }
}

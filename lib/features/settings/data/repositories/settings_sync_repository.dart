import 'dart:convert';

import '../../../../core/sync/sync.dart';
import '../datasources/drift_settings_local_datasource.dart';
import '../datasources/settings_supabase_datasource.dart';
import '../dtos/settings_dto.dart';

class SettingsSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const SettingsSyncRepository({
    required this.local,
    required this.remote,
    required this.userId,
    required this.afterCommit,
  });
  static const key = 'settings';
  final Future<DriftSettingsLocalDatasource> Function() local;
  final SettingsRemoteDatasource remote;
  final String userId;
  final Future<void> Function(SettingsDto settings) afterCommit;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await local()).pending()).map(_operation).toList();

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final dto = await (await local()).pendingById(recordId);
    return dto == null ? null : _operation(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final result = await remote.upsert(_dto(operation), userId);
    final applied = await (await local()).applyRemote(result);
    if (applied) await afterCommit(result);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await remote.pull(userId, updatedAfter)).map(_operation).toList();

  @override
  Future<void> applyRemote(SyncOperation operation) async {
    final dto = _dto(operation);
    final applied = await (await local()).applyRemote(dto);
    if (applied) await afterCommit(dto);
  }

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    final dto = _dto(operation);
    final applied = await (await local()).applyRemoteAndMarkSynced(dto);
    if (applied) await afterCommit(dto);
  }

  @override
  Future<void> markSynced(
    String recordId, {
    required DateTime syncedAt,
  }) async => (await local()).markSynced(recordId);

  @override
  Future<void> markFailed(String recordId, SyncError error) async =>
      (await local()).markFailed(recordId, error.message);

  @override
  Future<DateTime?> getLastPullAt() async => (await local()).getLastPullAt();

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async =>
      (await local()).saveCursor(completedAt);

  SyncOperation _operation(SettingsDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.id,
    type: dto.syncMetadata.deletedAt != null
        ? SyncOperationType.delete
        : dto.syncMetadata.syncStatus == SyncStatus.pendingCreate
        ? SyncOperationType.create
        : SyncOperationType.update,
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: userId,
    payload: {
      ...dto.toSupabase(userId),
      'createdAt': dto.syncMetadata.createdAt.toIso8601String(),
    },
  );

  SettingsDto _dto(SyncOperation operation) {
    final payload = operation.payload;
    return SettingsDto(
      id: operation.recordId,
      dailyWaterGoalMl: payload['daily_water_goal_ml'] as int,
      vitaminRemindersEnabled: payload['vitamin_reminders_enabled'] as bool,
      medicationRemindersEnabled:
          payload['medication_reminders_enabled'] as bool,
      appointmentRemindersEnabled:
          payload['appointment_reminders_enabled'] as bool,
      mealTrackingEnabled: payload['meal_tracking_enabled'] as bool,
      treatmentTrackingEnabled:
          payload['treatment_tracking_enabled'] as bool? ?? true,
      waterTrackingEnabled: payload['water_tracking_enabled'] as bool? ?? true,
      weightTrackingEnabled:
          payload['weight_tracking_enabled'] as bool? ?? true,
      weightUnit: payload['weight_unit'] as String,
      notificationPreferencesJson: _encodedPreferences(
        payload['notification_preferences'],
      ),
      syncMetadata: SyncMetadata(
        id: operation.recordId,
        userId: userId,
        createdAt: DateTime.parse(
          (payload['created_at'] ?? payload['createdAt']) as String,
        ),
        updatedAt: operation.updatedAt,
        deletedAt: operation.deletedAt,
        syncStatus: operation.syncStatus,
      ),
    );
  }

  static String _encodedPreferences(Object? value) {
    if (value is String) return value;
    return jsonEncode(value ?? const <String, Object?>{});
  }
}

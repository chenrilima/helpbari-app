import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/meal_dao.dart';
import '../../../../core/database/drift/migrations/meal_legacy_service.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/meal_dto.dart';
import '../../domain/value_objects/value_objects.dart';

class DriftMealLocalDatasource {
  const DriftMealLocalDatasource({
    required MealDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final MealDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != anonymousMealUserId;

  Future<List<MealDto>> getAll() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();
  Future<List<MealDto>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => (await _dao.getActiveByUserInRange(
    userId,
    startInclusive,
    endExclusive,
    limit: limit,
  )).map(_fromDrift).toList();
  Future<MealDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromDrift(row);
  }

  Future<void> save(MealDto meal) async {
    final previous = await getById(meal.id);
    final dto = MealDto.fromEntity(
      meal.toEntity(clock: _clock),
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata.copyWith(userId: userId),
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final previous = await getById(id);
    if (previous == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        MealDto(
          id: previous.id,
          name: previous.name,
          type: previous.type,
          mealDate: previous.mealDate,
          notes: previous.notes,
          proteinGrams: previous.proteinGrams,
          syncMetadata: previous.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<MealDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pendingDto).toList()
      : const [];
  Future<MealDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null || row.syncStatus == SyncStatus.synced.name) return null;
    return _pendingDto(row);
  }

  Future<void> applyRemote(MealDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(MealDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.id);
      });
  Future<void> markSynced(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(_syncCopy(row, status: SyncStatus.synced, attempts: 0));
    }
  }

  Future<void> markFailed(String id, String error) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(
        _syncCopy(
          row,
          status: SyncStatus.failed,
          previousStatus: row.previousSyncStatus ?? row.syncStatus,
          attempts: row.syncAttempts + 1,
          error: error,
        ),
      );
    }
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  MealDto _pendingDto(MealRecord row) {
    final dto = _fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return MealDto(
      id: dto.id,
      name: dto.name,
      type: dto.type,
      mealDate: dto.mealDate,
      notes: dto.notes,
      proteinGrams: dto.proteinGrams,
      syncMetadata: dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  MealDto _fromDrift(MealRecord row) => MealDto(
    id: row.id,
    name: row.name,
    type: MealType.values.firstWhere(
      (type) => type.name == row.type,
      orElse: () => MealType.snack,
    ),
    mealDate: row.mealDate,
    notes: row.notes,
    proteinGrams: row.proteinGrams,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );
  MealRecordsCompanion _companion(MealDto dto) => MealRecordsCompanion.insert(
    id: dto.id,
    userId: userId,
    name: dto.name,
    type: dto.type.name,
    mealDate: dto.mealDate,
    notes: Value(dto.notes),
    proteinGrams: Value(dto.proteinGrams),
    createdAt: dto.syncMetadata.createdAt,
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: Value(dto.syncMetadata.deletedAt),
    syncStatus: dto.syncMetadata.syncStatus.name,
  );
  MealRecordsCompanion _syncCopy(
    MealRecord row, {
    required SyncStatus status,
    String? previousStatus,
    required int attempts,
    String? error,
  }) => MealRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    name: Value(row.name),
    type: Value(row.type),
    mealDate: Value(row.mealDate),
    notes: Value(row.notes),
    proteinGrams: Value(row.proteinGrams),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}

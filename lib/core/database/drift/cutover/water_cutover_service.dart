import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/water_local_consistency_checker.dart';
import '../consistency/water_local_snapshot.dart';
import '../migrations/water_local_migration_service.dart';

class WaterCutoverService {
  const WaterCutoverService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;

  static const migrationKey = 'water.drift.cutover';
  static const version = 1;
  static const _mirrorPrefix = 'core.water.cutover.v1';

  final AppDatabase _database;
  final LocalStorageService _storage;

  Future<bool> isCompleted(String userId) async {
    if (userId == anonymousWaterUserId) return false;
    final marker =
        await (_database.select(_database.waterCutovers)..where(
              (row) =>
                  row.migrationKey.equals(migrationKey) &
                  row.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (marker != null) {
      await _writeMirror(marker.userId, marker.checksum, marker.recordCount);
    }
    return marker != null;
  }

  bool isCompletedMirror(String userId) =>
      isCompletedMirrorFor(_storage, userId);

  static bool isCompletedMirrorFor(
    LocalStorageService storage,
    String userId,
  ) => storage.getString('$_mirrorPrefix.$userId') != null;

  Future<WaterCutoverResult> attempt(String userId) async {
    if (userId == anonymousWaterUserId) {
      return WaterCutoverResult.blocked('anonymous');
    }
    if (await isCompleted(userId)) {
      return const WaterCutoverResult.completed(alreadyCompleted: true);
    }

    final migration =
        await (_database.select(_database.localMigrations)..where(
              (row) => row.migrationKey.equals(
                WaterLocalMigrationService.migrationKey,
              ),
            ))
            .getSingleOrNull();
    if (migration == null) {
      return WaterCutoverResult.blocked('migration_missing');
    }

    final snapshot = WaterLegacySnapshotReader(_storage).read();
    if (snapshot.invalid > 0) {
      return WaterCutoverResult.blocked('invalid_legacy');
    }
    final report = await WaterLocalConsistencyChecker(
      database: _database,
      storage: _storage,
      includeCutoverUsers: true,
    ).check(userId: userId);
    if (report.missingInDrift > 0 ||
        report.divergent > 0 ||
        report.extraInDrift > 0) {
      return WaterCutoverResult.blocked('not_converged');
    }

    final records = snapshot.records
        .where((record) => record.userId == userId)
        .toList();
    final checksum = normalizedWaterChecksum(records);
    final completedAt = DateTime.now().toUtc();
    await _database.transaction(() async {
      await _database
          .into(_database.waterCutovers)
          .insertOnConflictUpdate(
            WaterCutoversCompanion.insert(
              migrationKey: migrationKey,
              version: version,
              userId: userId,
              completedAt: completedAt,
              checksum: checksum,
              recordCount: records.length,
              databaseSchemaVersion: _database.schemaVersion,
            ),
          );
    });
    await _writeMirror(userId, checksum, records.length);
    return const WaterCutoverResult.completed();
  }

  Future<void> _writeMirror(String userId, String checksum, int count) =>
      _storage.setString(
        '$_mirrorPrefix.$userId',
        jsonEncode({'version': version, 'checksum': checksum, 'count': count}),
      );
}

class WaterCutoverResult {
  const WaterCutoverResult.completed({this.alreadyCompleted = false})
    : completed = true,
      blockedReason = null;
  const WaterCutoverResult.blocked(this.blockedReason)
    : completed = false,
      alreadyCompleted = false;

  final bool completed;
  final bool alreadyCompleted;
  final String? blockedReason;
}

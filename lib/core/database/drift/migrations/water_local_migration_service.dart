import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/water_local_snapshot.dart';
import 'water_local_migration_report.dart';

class WaterLocalMigrationService {
  const WaterLocalMigrationService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;

  static const migrationKey = 'shared_preferences.water_records.v1';
  static const legacyStorageKey = waterLegacyStorageKey;
  static const anonymousUserId = anonymousWaterUserId;

  final AppDatabase _database;
  final LocalStorageService _storage;

  Future<WaterLocalMigrationReport> migrate() async {
    final snapshot = WaterLegacySnapshotReader(_storage).read();
    final cutoverUsers = (await _database.select(_database.waterCutovers).get())
        .map((row) => row.userId)
        .toSet();
    final candidates = snapshot.records
        .where((record) => !cutoverUsers.contains(record.userId))
        .toList();
    final checksum = normalizedWaterChecksum(candidates);
    var imported = 0;
    var updated = 0;
    var ignored = 0;

    await _database.transaction(() async {
      for (final candidate in candidates) {
        final existing =
            await (_database.select(_database.waterRecords)..where(
                  (row) =>
                      row.userId.equals(candidate.userId) &
                      row.id.equals(candidate.id),
                ))
                .getSingleOrNull();

        if (existing == null) {
          await _database
              .into(_database.waterRecords)
              .insert(candidate.companion);
          imported++;
        } else if (candidate.updatedAt.isAfter(existing.updatedAt)) {
          await _database
              .into(_database.waterRecords)
              .insertOnConflictUpdate(candidate.companion);
          updated++;
        } else {
          ignored++;
        }
      }

      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(checksum),
              importedCount: Value(candidates.length),
            ),
          );
    });

    return WaterLocalMigrationReport(
      read: snapshot.read,
      imported: imported,
      updated: updated,
      ignored: ignored,
      invalid: snapshot.invalid,
      anonymous: candidates.where((item) => item.isAnonymous).length,
      checksum: checksum,
    );
  }
}

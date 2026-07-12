import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const vitaminLegacyStorageKey = 'local_database.collection.vitamins';

class VitaminLegacyService {
  const VitaminLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.vitamins.daily.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final raw = _storage.getString(vitaminLegacyStorageKey);
    var imported = 0;
    await _database.transaction(() async {
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            try {
              final record = LocalDatabaseRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              );
              final name = record.data['name'] as String;
              final hour = record.data['hour'] as int;
              final minute = record.data['minute'] as int;
              final userId = record.metadata.userId?.trim().isNotEmpty == true
                  ? record.metadata.userId!
                  : 'anonymous';
              await _database
                  .into(_database.vitaminRecords)
                  .insertOnConflictUpdate(
                    VitaminRecordsCompanion.insert(
                      id: record.id,
                      userId: userId,
                      name: name,
                      scheduleHour: hour,
                      scheduleMinute: minute,
                      createdAt: record.metadata.createdAt,
                      updatedAt: record.metadata.updatedAt,
                      deletedAt: Value(record.metadata.deletedAt),
                      syncStatus: record.metadata.syncStatus.name,
                    ),
                  );
              final status = record.data['status'] as String? ?? 'pending';
              final day = DateTime(
                record.metadata.updatedAt.year,
                record.metadata.updatedAt.month,
                record.metadata.updatedAt.day,
              );
              await _database
                  .into(_database.vitaminLogRecords)
                  .insertOnConflictUpdate(
                    VitaminLogRecordsCompanion.insert(
                      id: record.id,
                      userId: userId,
                      vitaminId: record.id,
                      logDate: day,
                      status:
                          const {'pending', 'taken', 'skipped'}.contains(status)
                          ? status
                          : 'pending',
                      createdAt: record.metadata.createdAt,
                      updatedAt: record.metadata.updatedAt,
                      deletedAt: Value(record.metadata.deletedAt),
                      syncStatus: record.metadata.syncStatus.name,
                    ),
                  );
              imported++;
            } catch (_) {
              /* Invalid legacy rows remain untouched in SharedPreferences. */
            }
          }
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              importedCount: Value(imported),
            ),
          );
    });
  }
}

import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const medicationLegacyStorageKey = 'local_database.collection.medications';

class MedicationLegacyService {
  const MedicationLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.medications.daily.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final raw = _storage.getString(medicationLegacyStorageKey);
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
              final userId = record.metadata.userId?.trim().isNotEmpty == true
                  ? record.metadata.userId!
                  : 'anonymous';
              final data = record.data;
              await _database
                  .into(_database.medicationRecords)
                  .insertOnConflictUpdate(
                    MedicationRecordsCompanion.insert(
                      id: record.id,
                      userId: userId,
                      name: data['name'] as String,
                      scheduleHour: data['hour'] as int,
                      scheduleMinute: data['minute'] as int,
                      dosage: Value(data['dosage'] as String?),
                      notes: Value(data['notes'] as String?),
                      createdAt: record.metadata.createdAt,
                      updatedAt: record.metadata.updatedAt,
                      deletedAt: Value(record.metadata.deletedAt),
                      syncStatus: record.metadata.syncStatus.name,
                    ),
                  );
              final status = data['status'] as String? ?? 'pending';
              final updated = record.metadata.updatedAt;
              await _database
                  .into(_database.medicationLogRecords)
                  .insertOnConflictUpdate(
                    MedicationLogRecordsCompanion.insert(
                      id: record.id,
                      userId: userId,
                      medicationId: record.id,
                      logDate: DateTime(
                        updated.year,
                        updated.month,
                        updated.day,
                      ),
                      status:
                          const {'pending', 'taken', 'skipped'}.contains(status)
                          ? status
                          : 'pending',
                      createdAt: record.metadata.createdAt,
                      updatedAt: updated,
                      deletedAt: Value(record.metadata.deletedAt),
                      syncStatus: record.metadata.syncStatus.name,
                    ),
                  );
              imported++;
            } catch (_) {
              /* Preserve invalid legacy rows untouched. */
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

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const weightLegacyStorageKey = 'local_database.collection.weight_records';
const anonymousWeightUserId = 'anonymous';

class NormalizedWeightRecord {
  const NormalizedWeightRecord({
    required this.userId,
    required this.id,
    required this.weight,
    required this.recordedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });
  factory NormalizedWeightRecord.fromLegacy(Map<String, dynamic> json) {
    final record = LocalDatabaseRecord.fromJson(json);
    final weight = record.data['weight'];
    final recordedAt = record.data['recordedAt'];
    if (record.id.isEmpty ||
        weight is! num ||
        weight <= 0 ||
        recordedAt is! String) {
      throw const FormatException('Invalid weight record');
    }
    final rawUser = record.metadata.userId?.trim();
    return NormalizedWeightRecord(
      userId: rawUser == null || rawUser.isEmpty
          ? anonymousWeightUserId
          : rawUser,
      id: record.id,
      weight: weight.toDouble(),
      recordedAt: DateTime.parse(recordedAt),
      notes: record.data['notes'] as String?,
      createdAt: record.metadata.createdAt,
      updatedAt: record.metadata.updatedAt,
      deletedAt: record.metadata.deletedAt,
      syncStatus: record.metadata.syncStatus.name,
    );
  }
  factory NormalizedWeightRecord.fromDrift(WeightRecord row) =>
      NormalizedWeightRecord(
        userId: row.userId,
        id: row.id,
        weight: row.weightKg,
        recordedAt: row.recordedAt,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: row.syncStatus,
      );
  final String userId, id, syncStatus;
  final double weight;
  final DateTime recordedAt, createdAt, updatedAt;
  final DateTime? deletedAt;
  final String? notes;
  WeightRecordsCompanion get companion => WeightRecordsCompanion.insert(
    id: id,
    userId: userId,
    weightKg: weight,
    recordedAt: recordedAt,
    notes: Value(notes),
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    syncStatus: syncStatus,
  );
  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': id,
    'weight': weight,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'syncStatus': syncStatus,
  };
}

class WeightLegacySnapshot {
  const WeightLegacySnapshot(this.records, this.read, this.invalid);
  final List<NormalizedWeightRecord> records;
  final int read, invalid;
}

WeightLegacySnapshot readWeightLegacy(LocalStorageService storage) {
  final raw = storage.getString(weightLegacyStorageKey);
  if (raw == null || raw.isEmpty) return const WeightLegacySnapshot([], 0, 0);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const WeightLegacySnapshot([], 1, 1);
    final records = <NormalizedWeightRecord>[];
    var invalid = 0;
    for (final item in decoded) {
      try {
        records.add(
          NormalizedWeightRecord.fromLegacy(
            Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (_) {
        invalid++;
      }
    }
    return WeightLegacySnapshot(records, decoded.length, invalid);
  } catch (_) {
    return const WeightLegacySnapshot([], 1, 1);
  }
}

String weightChecksum(Iterable<NormalizedWeightRecord> records) {
  final values = records.map((e) => e.normalized).toList()
    ..sort(
      (a, b) =>
          '${a['userId']}:${a['id']}'.compareTo('${b['userId']}:${b['id']}'),
    );
  return sha256.convert(utf8.encode(jsonEncode(values))).toString();
}

class WeightLegacyService {
  const WeightLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.weight_records.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final snapshot = readWeightLegacy(_storage);
    final cutovers = (await _database.select(_database.weightCutovers).get())
        .map((e) => e.userId)
        .toSet();
    final records = snapshot.records.where((e) => !cutovers.contains(e.userId));
    await _database.transaction(() async {
      for (final candidate in records) {
        final existing =
            await (_database.select(_database.weightRecords)..where(
                  (row) =>
                      row.userId.equals(candidate.userId) &
                      row.id.equals(candidate.id),
                ))
                .getSingleOrNull();
        if (existing == null ||
            candidate.updatedAt.isAfter(existing.updatedAt)) {
          await _database
              .into(_database.weightRecords)
              .insertOnConflictUpdate(candidate.companion);
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(weightChecksum(records)),
              importedCount: Value(records.length),
            ),
          );
    });
  }
}

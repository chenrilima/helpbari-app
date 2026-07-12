import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const mealLegacyStorageKey = 'local_database.collection.meals';
const anonymousMealUserId = 'anonymous';

class NormalizedMealRecord {
  const NormalizedMealRecord({
    required this.userId,
    required this.id,
    required this.name,
    required this.type,
    required this.mealDate,
    required this.notes,
    required this.proteinGrams,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });
  factory NormalizedMealRecord.fromLegacy(Map<String, dynamic> json) {
    final record = LocalDatabaseRecord.fromJson(json);
    final data = record.data;
    final name = data['name'],
        type = data['type'],
        mealDate = data['mealDate'],
        protein = data['proteinGrams'];
    if (record.id.isEmpty ||
        name is! String ||
        name.trim().length < 2 ||
        type is! String ||
        !const {'breakfast', 'lunch', 'dinner', 'snack'}.contains(type) ||
        mealDate is! String ||
        (protein != null && (protein is! int || protein < 0))) {
      throw const FormatException('Invalid meal record');
    }
    final rawUser = record.metadata.userId?.trim();
    return NormalizedMealRecord(
      userId: rawUser == null || rawUser.isEmpty
          ? anonymousMealUserId
          : rawUser,
      id: record.id,
      name: name.trim(),
      type: type,
      mealDate: DateTime.parse(mealDate),
      notes: data['notes'] as String?,
      proteinGrams: protein as int?,
      createdAt: record.metadata.createdAt,
      updatedAt: record.metadata.updatedAt,
      deletedAt: record.metadata.deletedAt,
      syncStatus: record.metadata.syncStatus.name,
    );
  }
  factory NormalizedMealRecord.fromDrift(MealRecord row) =>
      NormalizedMealRecord(
        userId: row.userId,
        id: row.id,
        name: row.name,
        type: row.type,
        mealDate: row.mealDate,
        notes: row.notes,
        proteinGrams: row.proteinGrams,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: row.syncStatus,
      );
  final String userId, id, name, type, syncStatus;
  final DateTime mealDate, createdAt, updatedAt;
  final DateTime? deletedAt;
  final String? notes;
  final int? proteinGrams;
  MealRecordsCompanion get companion => MealRecordsCompanion.insert(
    id: id,
    userId: userId,
    name: name,
    type: type,
    mealDate: mealDate,
    notes: Value(notes),
    proteinGrams: Value(proteinGrams),
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    syncStatus: syncStatus,
  );
  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': id,
    'name': name,
    'type': type,
    'mealDate': mealDate.toUtc().toIso8601String(),
    'notes': notes,
    'proteinGrams': proteinGrams,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'syncStatus': syncStatus,
  };
}

class MealLegacySnapshot {
  const MealLegacySnapshot(this.records, this.read, this.invalid);
  final List<NormalizedMealRecord> records;
  final int read, invalid;
}

MealLegacySnapshot readMealLegacy(LocalStorageService storage) {
  final raw = storage.getString(mealLegacyStorageKey);
  if (raw == null || raw.isEmpty) return const MealLegacySnapshot([], 0, 0);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const MealLegacySnapshot([], 1, 1);
    final records = <NormalizedMealRecord>[];
    var invalid = 0;
    for (final item in decoded) {
      try {
        records.add(
          NormalizedMealRecord.fromLegacy(
            Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (_) {
        invalid++;
      }
    }
    return MealLegacySnapshot(records, decoded.length, invalid);
  } catch (_) {
    return const MealLegacySnapshot([], 1, 1);
  }
}

String mealChecksum(Iterable<NormalizedMealRecord> records) {
  final values = records.map((record) => record.normalized).toList()
    ..sort(
      (a, b) =>
          '${a['userId']}:${a['id']}'.compareTo('${b['userId']}:${b['id']}'),
    );
  return sha256.convert(utf8.encode(jsonEncode(values))).toString();
}

class MealLegacyService {
  const MealLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.meals.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final snapshot = readMealLegacy(_storage);
    final cutovers = (await _database.select(_database.mealCutovers).get())
        .map((row) => row.userId)
        .toSet();
    final candidates = snapshot.records
        .where((record) => !cutovers.contains(record.userId))
        .toList();
    await _database.transaction(() async {
      for (final candidate in candidates) {
        final existing =
            await (_database.select(_database.mealRecords)..where(
                  (row) =>
                      row.userId.equals(candidate.userId) &
                      row.id.equals(candidate.id),
                ))
                .getSingleOrNull();
        if (existing == null ||
            candidate.updatedAt.isAfter(existing.updatedAt)) {
          await _database
              .into(_database.mealRecords)
              .insertOnConflictUpdate(candidate.companion);
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(mealChecksum(candidates)),
              importedCount: Value(candidates.length),
            ),
          );
    });
  }
}

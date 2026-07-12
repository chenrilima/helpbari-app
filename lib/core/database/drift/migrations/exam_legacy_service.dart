import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const examLegacyStorageKey = 'local_database.collection.exams';
const anonymousExamUserId = 'anonymous';

class NormalizedExamRecord {
  const NormalizedExamRecord({
    required this.userId,
    required this.id,
    required this.name,
    required this.examDate,
    required this.laboratory,
    required this.notes,
    required this.attachmentPath,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });
  factory NormalizedExamRecord.fromLegacy(Map<String, dynamic> json) {
    final r = LocalDatabaseRecord.fromJson(json), d = r.data;
    final name = d['name'], date = d['examDate'];
    if (r.id.isEmpty ||
        name is! String ||
        name.trim().length < 2 ||
        date is! String) {
      throw const FormatException('Invalid exam');
    }
    final raw = r.metadata.userId?.trim();
    return NormalizedExamRecord(
      userId: raw == null || raw.isEmpty ? anonymousExamUserId : raw,
      id: r.id,
      name: name.trim(),
      examDate: DateTime.parse(date),
      laboratory: d['laboratory'] as String?,
      notes: d['notes'] as String?,
      attachmentPath: d['attachmentPath'] as String?,
      createdAt: r.metadata.createdAt,
      updatedAt: r.metadata.updatedAt,
      deletedAt: r.metadata.deletedAt,
      syncStatus: r.metadata.syncStatus.name,
    );
  }
  factory NormalizedExamRecord.fromDrift(ExamRecord r) => NormalizedExamRecord(
    userId: r.userId,
    id: r.id,
    name: r.name,
    examDate: r.examDate,
    laboratory: r.laboratory,
    notes: r.notes,
    attachmentPath: r.attachmentPath,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    deletedAt: r.deletedAt,
    syncStatus: r.syncStatus,
  );
  final String userId, id, name, syncStatus;
  final DateTime examDate, createdAt, updatedAt;
  final DateTime? deletedAt;
  final String? laboratory, notes, attachmentPath;
  ExamRecordsCompanion get companion => ExamRecordsCompanion.insert(
    id: id,
    userId: userId,
    name: name,
    examDate: examDate,
    laboratory: Value(laboratory),
    notes: Value(notes),
    attachmentPath: Value(attachmentPath),
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    syncStatus: syncStatus,
  );
  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': id,
    'name': name,
    'examDate': examDate.toUtc().toIso8601String(),
    'laboratory': laboratory,
    'notes': notes,
    'attachmentPath': attachmentPath,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'syncStatus': syncStatus,
  };
}

class ExamLegacySnapshot {
  const ExamLegacySnapshot(this.records, this.invalid);
  final List<NormalizedExamRecord> records;
  final int invalid;
}

ExamLegacySnapshot readExamLegacy(LocalStorageService storage) {
  final raw = storage.getString(examLegacyStorageKey);
  if (raw == null || raw.isEmpty) return const ExamLegacySnapshot([], 0);
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const ExamLegacySnapshot([], 1);
    final records = <NormalizedExamRecord>[];
    var invalid = 0;
    for (final item in decoded) {
      try {
        records.add(
          NormalizedExamRecord.fromLegacy(
            Map<String, dynamic>.from(item as Map),
          ),
        );
      } catch (_) {
        invalid++;
      }
    }
    return ExamLegacySnapshot(records, invalid);
  } catch (_) {
    return const ExamLegacySnapshot([], 1);
  }
}

String examChecksum(Iterable<NormalizedExamRecord> records) {
  final values = records.map((r) => r.normalized).toList()
    ..sort(
      (a, b) =>
          '${a['userId']}:${a['id']}'.compareTo('${b['userId']}:${b['id']}'),
    );
  return sha256.convert(utf8.encode(jsonEncode(values))).toString();
}

class ExamLegacyService {
  const ExamLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'shared_preferences.exams.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  Future<void> migrate() async {
    final snapshot = readExamLegacy(_storage);
    final cutovers = (await _database.select(_database.examCutovers).get())
        .map((r) => r.userId)
        .toSet();
    final candidates = snapshot.records
        .where((r) => !cutovers.contains(r.userId))
        .toList();
    await _database.transaction(() async {
      for (final c in candidates) {
        final existing =
            await (_database.select(_database.examRecords)
                  ..where((r) => r.userId.equals(c.userId) & r.id.equals(c.id)))
                .getSingleOrNull();
        if (existing == null || c.updatedAt.isAfter(existing.updatedAt)) {
          await _database
              .into(_database.examRecords)
              .insertOnConflictUpdate(c.companion);
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(examChecksum(candidates)),
              importedCount: Value(candidates.length),
            ),
          );
    });
  }
}

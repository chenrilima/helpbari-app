import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/exam_local_consistency_checker.dart';
import '../migrations/exam_legacy_service.dart';

class ExamCutoverService {
  const ExamCutoverService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'exams.drift.cutover';
  static const _mirror = 'core.exams.cutover.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  static bool isCompletedMirrorFor(LocalStorageService s, String u) =>
      s.getString('$_mirror.$u') != null;
  Future<bool> isCompleted(String u) async =>
      u != anonymousExamUserId &&
      await (_database.select(
            _database.examCutovers,
          )..where((r) => r.userId.equals(u))).getSingleOrNull() !=
          null;
  Future<bool> attempt(String u) async {
    if (u == anonymousExamUserId) return false;
    if (await isCompleted(u)) return true;
    final migration =
        await (_database.select(_database.localMigrations)..where(
              (r) => r.migrationKey.equals(ExamLegacyService.migrationKey),
            ))
            .getSingleOrNull();
    if (migration == null) return false;
    final report = await ExamLocalConsistencyChecker(
      database: _database,
      storage: _storage,
      includeCutoverUsers: true,
    ).check(userId: u);
    if (!report.consistent) return false;
    final records = readExamLegacy(
      _storage,
    ).records.where((r) => r.userId == u).toList();
    final checksum = examChecksum(records);
    await _database
        .into(_database.examCutovers)
        .insertOnConflictUpdate(
          ExamCutoversCompanion.insert(
            migrationKey: migrationKey,
            version: 1,
            userId: u,
            completedAt: DateTime.now().toUtc(),
            checksum: checksum,
            recordCount: records.length,
            databaseSchemaVersion: _database.schemaVersion,
          ),
        );
    await _storage.setString(
      '$_mirror.$u',
      jsonEncode({'version': 1, 'checksum': checksum, 'count': records.length}),
    );
    return true;
  }
}

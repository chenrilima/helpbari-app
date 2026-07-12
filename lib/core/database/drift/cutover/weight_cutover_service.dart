import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/weight_local_consistency_checker.dart';
import '../migrations/weight_legacy_service.dart';

class WeightCutoverService {
  const WeightCutoverService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'weight.drift.cutover';
  static const _mirrorPrefix = 'core.weight.cutover.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  bool isCompletedMirror(String userId) =>
      _storage.getString('$_mirrorPrefix.$userId') != null;
  static bool isCompletedMirrorFor(
    LocalStorageService storage,
    String userId,
  ) => storage.getString('$_mirrorPrefix.$userId') != null;
  Future<bool> isCompleted(String userId) async =>
      userId != anonymousWeightUserId &&
      await (_database.select(
            _database.weightCutovers,
          )..where((r) => r.userId.equals(userId))).getSingleOrNull() !=
          null;
  Future<bool> attempt(String userId) async {
    if (userId == anonymousWeightUserId) return false;
    if (await isCompleted(userId)) return true;
    final migration =
        await (_database.select(_database.localMigrations)..where(
              (r) => r.migrationKey.equals(WeightLegacyService.migrationKey),
            ))
            .getSingleOrNull();
    if (migration == null) return false;
    final report = await WeightLocalConsistencyChecker(
      database: _database,
      storage: _storage,
      includeCutoverUsers: true,
    ).check(userId: userId);
    if (!report.consistent) return false;
    final records = readWeightLegacy(
      _storage,
    ).records.where((e) => e.userId == userId).toList();
    final checksum = weightChecksum(records);
    await _database
        .into(_database.weightCutovers)
        .insertOnConflictUpdate(
          WeightCutoversCompanion.insert(
            migrationKey: migrationKey,
            version: 1,
            userId: userId,
            completedAt: DateTime.now().toUtc(),
            checksum: checksum,
            recordCount: records.length,
            databaseSchemaVersion: _database.schemaVersion,
          ),
        );
    await _storage.setString(
      '$_mirrorPrefix.$userId',
      jsonEncode({'version': 1, 'checksum': checksum, 'count': records.length}),
    );
    return true;
  }
}

import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/meal_local_consistency_checker.dart';
import '../migrations/meal_legacy_service.dart';

class MealCutoverService {
  const MealCutoverService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'meals.drift.cutover';
  static const _mirrorPrefix = 'core.meals.cutover.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  static bool isCompletedMirrorFor(
    LocalStorageService storage,
    String userId,
  ) => storage.getString('$_mirrorPrefix.$userId') != null;
  Future<bool> isCompleted(String userId) async =>
      userId != anonymousMealUserId &&
      await (_database.select(
            _database.mealCutovers,
          )..where((row) => row.userId.equals(userId))).getSingleOrNull() !=
          null;
  Future<bool> attempt(String userId) async {
    if (userId == anonymousMealUserId) return false;
    if (await isCompleted(userId)) return true;
    final migration =
        await (_database.select(_database.localMigrations)..where(
              (row) => row.migrationKey.equals(MealLegacyService.migrationKey),
            ))
            .getSingleOrNull();
    if (migration == null) return false;
    final report = await MealLocalConsistencyChecker(
      database: _database,
      storage: _storage,
      includeCutoverUsers: true,
    ).check(userId: userId);
    if (!report.consistent) return false;
    final records = readMealLegacy(
      _storage,
    ).records.where((record) => record.userId == userId).toList();
    final checksum = mealChecksum(records);
    await _database
        .into(_database.mealCutovers)
        .insertOnConflictUpdate(
          MealCutoversCompanion.insert(
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

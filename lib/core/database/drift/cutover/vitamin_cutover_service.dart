import '../app_database.dart';
import '../consistency/vitamin_local_consistency_checker.dart';

class VitaminCutoverService {
  const VitaminCutoverService(this.database);
  final AppDatabase database;
  Future<bool> attempt(String userId) async {
    if (userId == 'anonymous') return false;
    final existing = await (database.select(
      database.vitaminCutovers,
    )..where((r) => r.userId.equals(userId))).getSingleOrNull();
    if (existing != null) return true;
    if (!await VitaminLocalConsistencyChecker(database).check(userId)) {
      return false;
    }
    final vitamins = await (database.select(
      database.vitaminRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final logs = await (database.select(
      database.vitaminLogRecords,
    )..where((r) => r.userId.equals(userId))).get();
    await database
        .into(database.vitaminCutovers)
        .insertOnConflictUpdate(
          VitaminCutoversCompanion.insert(
            userId: userId,
            completedAt: DateTime.now().toUtc(),
            databaseSchemaVersion: database.schemaVersion,
            migratedVitaminCount: vitamins.length,
            migratedLogCount: logs.length,
          ),
        );
    return true;
  }
}

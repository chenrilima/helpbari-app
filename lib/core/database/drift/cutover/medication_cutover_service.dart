import '../app_database.dart';
import '../consistency/medication_local_consistency_checker.dart';

class MedicationCutoverService {
  const MedicationCutoverService(this.database);
  final AppDatabase database;
  Future<bool> attempt(String userId) async {
    if (userId == 'anonymous') return false;
    final old = await (database.select(
      database.medicationCutovers,
    )..where((r) => r.userId.equals(userId))).getSingleOrNull();
    if (old != null) return true;
    if (!await MedicationLocalConsistencyChecker(database).check(userId)) {
      return false;
    }
    final medications = await (database.select(
      database.medicationRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final logs = await (database.select(
      database.medicationLogRecords,
    )..where((r) => r.userId.equals(userId))).get();
    await database
        .into(database.medicationCutovers)
        .insertOnConflictUpdate(
          MedicationCutoversCompanion.insert(
            userId: userId,
            completedAt: DateTime.now().toUtc(),
            databaseSchemaVersion: database.schemaVersion,
            migratedMedicationCount: medications.length,
            migratedLogCount: logs.length,
          ),
        );
    return true;
  }
}

import '../app_database.dart';

class MedicationLocalConsistencyChecker {
  const MedicationLocalConsistencyChecker(this.database);
  final AppDatabase database;
  Future<bool> check(String userId) async {
    final medications = await (database.select(
      database.medicationRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final logs = await (database.select(
      database.medicationLogRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final ids = medications.map((v) => v.id).toSet();
    return logs.every((l) => ids.contains(l.medicationId));
  }
}

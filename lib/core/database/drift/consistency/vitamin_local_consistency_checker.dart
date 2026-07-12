import '../app_database.dart';

class VitaminLocalConsistencyChecker {
  const VitaminLocalConsistencyChecker(this.database);
  final AppDatabase database;
  Future<bool> check(String userId) async {
    final vitamins = await (database.select(
      database.vitaminRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final logs = await (database.select(
      database.vitaminLogRecords,
    )..where((r) => r.userId.equals(userId))).get();
    final ids = vitamins.map((v) => v.id).toSet();
    return logs.every((log) => ids.contains(log.vitaminId));
  }
}

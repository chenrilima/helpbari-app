import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/meal_legacy_service.dart';

class MealLocalConsistencyReport {
  const MealLocalConsistencyReport({
    required this.consistent,
    required this.invalidLegacy,
    required this.missing,
    required this.extra,
    required this.divergent,
  });
  final bool consistent;
  final int invalidLegacy, missing, extra, divergent;
}

class MealLocalConsistencyChecker {
  const MealLocalConsistencyChecker({
    required AppDatabase database,
    required LocalStorageService storage,
    this.includeCutoverUsers = false,
  }) : _database = database,
       _storage = storage;
  final AppDatabase _database;
  final LocalStorageService _storage;
  final bool includeCutoverUsers;
  Future<MealLocalConsistencyReport> check({String? userId}) async {
    final snapshot = readMealLegacy(_storage);
    final cutovers = includeCutoverUsers
        ? <String>{}
        : (await _database.select(_database.mealCutovers).get())
              .map((row) => row.userId)
              .toSet();
    final legacy = {
      for (final record in snapshot.records.where(
        (record) =>
            !cutovers.contains(record.userId) &&
            (userId == null || record.userId == userId),
      ))
        '${record.userId}:${record.id}': record,
    };
    final drift = {
      for (final row in await _database.select(_database.mealRecords).get())
        if (!cutovers.contains(row.userId) &&
            (userId == null || row.userId == userId))
          '${row.userId}:${row.id}': NormalizedMealRecord.fromDrift(row),
    };
    var missing = 0, extra = 0, divergent = 0;
    for (final key in {...legacy.keys, ...drift.keys}) {
      if (!drift.containsKey(key)) {
        missing++;
      } else if (!legacy.containsKey(key)) {
        extra++;
      } else if (jsonEncode(legacy[key]!.normalized) !=
          jsonEncode(drift[key]!.normalized)) {
        divergent++;
      }
    }
    return MealLocalConsistencyReport(
      consistent:
          snapshot.invalid == 0 && missing == 0 && extra == 0 && divergent == 0,
      invalidLegacy: snapshot.invalid,
      missing: missing,
      extra: extra,
      divergent: divergent,
    );
  }
}

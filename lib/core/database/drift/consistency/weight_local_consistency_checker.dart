import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/weight_legacy_service.dart';

class WeightLocalConsistencyReport {
  const WeightLocalConsistencyReport({
    required this.consistent,
    required this.invalidLegacy,
    required this.missing,
    required this.extra,
    required this.divergent,
  });
  final bool consistent;
  final int invalidLegacy, missing, extra, divergent;
}

class WeightLocalConsistencyChecker {
  const WeightLocalConsistencyChecker({
    required AppDatabase database,
    required LocalStorageService storage,
    this.includeCutoverUsers = false,
  }) : _database = database,
       _storage = storage;
  final AppDatabase _database;
  final LocalStorageService _storage;
  final bool includeCutoverUsers;
  Future<WeightLocalConsistencyReport> check({String? userId}) async {
    final snapshot = readWeightLegacy(_storage);
    final cutovers = includeCutoverUsers
        ? <String>{}
        : (await _database.select(_database.weightCutovers).get())
              .map((e) => e.userId)
              .toSet();
    final legacy = {
      for (final e in snapshot.records.where(
        (e) =>
            !cutovers.contains(e.userId) &&
            (userId == null || e.userId == userId),
      ))
        '${e.userId}:${e.id}': e,
    };
    final drift = {
      for (final row in await _database.select(_database.weightRecords).get())
        if (!cutovers.contains(row.userId) &&
            (userId == null || row.userId == userId))
          '${row.userId}:${row.id}': NormalizedWeightRecord.fromDrift(row),
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
    return WeightLocalConsistencyReport(
      consistent:
          snapshot.invalid == 0 && missing == 0 && extra == 0 && divergent == 0,
      invalidLegacy: snapshot.invalid,
      missing: missing,
      extra: extra,
      divergent: divergent,
    );
  }
}

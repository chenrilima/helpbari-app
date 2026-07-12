import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/exam_legacy_service.dart';

class ExamLocalConsistencyReport {
  const ExamLocalConsistencyReport(
    this.consistent,
    this.invalid,
    this.missing,
    this.extra,
    this.divergent,
  );
  final bool consistent;
  final int invalid, missing, extra, divergent;
}

class ExamLocalConsistencyChecker {
  const ExamLocalConsistencyChecker({
    required AppDatabase database,
    required LocalStorageService storage,
    this.includeCutoverUsers = false,
  }) : _database = database,
       _storage = storage;
  final AppDatabase _database;
  final LocalStorageService _storage;
  final bool includeCutoverUsers;
  Future<ExamLocalConsistencyReport> check({String? userId}) async {
    final snapshot = readExamLegacy(_storage);
    final cutovers = includeCutoverUsers
        ? <String>{}
        : (await _database.select(_database.examCutovers).get())
              .map((r) => r.userId)
              .toSet();
    final legacy = {
      for (final r in snapshot.records.where(
        (r) =>
            !cutovers.contains(r.userId) &&
            (userId == null || r.userId == userId),
      ))
        '${r.userId}:${r.id}': r,
    };
    final drift = {
      for (final r in await _database.select(_database.examRecords).get())
        if (!cutovers.contains(r.userId) &&
            (userId == null || r.userId == userId))
          '${r.userId}:${r.id}': NormalizedExamRecord.fromDrift(r),
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
    return ExamLocalConsistencyReport(
      snapshot.invalid == 0 && missing == 0 && extra == 0 && divergent == 0,
      snapshot.invalid,
      missing,
      extra,
      divergent,
    );
  }
}

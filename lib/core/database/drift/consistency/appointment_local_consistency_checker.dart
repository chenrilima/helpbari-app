import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/appointment_legacy_service.dart';

class AppointmentLocalConsistencyReport {
  const AppointmentLocalConsistencyReport(
    this.consistent,
    this.invalid,
    this.missing,
    this.extra,
    this.divergent,
  );
  final bool consistent;
  final int invalid, missing, extra, divergent;
}

class AppointmentLocalConsistencyChecker {
  const AppointmentLocalConsistencyChecker({
    required AppDatabase database,
    required LocalStorageService storage,
    this.includeCutoverUsers = false,
  }) : _database = database,
       _storage = storage;
  final AppDatabase _database;
  final LocalStorageService _storage;
  final bool includeCutoverUsers;
  Future<AppointmentLocalConsistencyReport> check({String? userId}) async {
    final snapshot = readAppointmentLegacy(_storage);
    final cutovers = includeCutoverUsers
        ? <String>{}
        : (await _database.select(_database.appointmentCutovers).get())
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
      for (final r
          in await _database.select(_database.appointmentRecords).get())
        if (!cutovers.contains(r.userId) &&
            (userId == null || r.userId == userId))
          '${r.userId}:${r.id}': NormalizedAppointmentRecord.fromDrift(r),
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
    return AppointmentLocalConsistencyReport(
      snapshot.invalid == 0 && missing == 0 && extra == 0 && divergent == 0,
      snapshot.invalid,
      missing,
      extra,
      divergent,
    );
  }
}

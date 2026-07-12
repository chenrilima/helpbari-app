import 'dart:convert';
import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../consistency/appointment_local_consistency_checker.dart';
import '../migrations/appointment_legacy_service.dart';

class AppointmentCutoverService {
  const AppointmentCutoverService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;
  static const migrationKey = 'appointments.drift.cutover';
  static const _mirror = 'core.appointments.cutover.v1';
  final AppDatabase _database;
  final LocalStorageService _storage;
  static bool isCompletedMirrorFor(
    LocalStorageService storage,
    String userId,
  ) => storage.getString('$_mirror.$userId') != null;
  Future<bool> isCompleted(String userId) async =>
      userId != anonymousAppointmentUserId &&
      await (_database.select(
            _database.appointmentCutovers,
          )..where((r) => r.userId.equals(userId))).getSingleOrNull() !=
          null;
  Future<bool> attempt(String userId) async {
    if (userId == anonymousAppointmentUserId) return false;
    if (await isCompleted(userId)) return true;
    final migration =
        await (_database.select(_database.localMigrations)..where(
              (r) =>
                  r.migrationKey.equals(AppointmentLegacyService.migrationKey),
            ))
            .getSingleOrNull();
    if (migration == null) return false;
    final report = await AppointmentLocalConsistencyChecker(
      database: _database,
      storage: _storage,
      includeCutoverUsers: true,
    ).check(userId: userId);
    if (!report.consistent) return false;
    final records = readAppointmentLegacy(
      _storage,
    ).records.where((r) => r.userId == userId).toList();
    final checksum = appointmentChecksum(records);
    await _database
        .into(_database.appointmentCutovers)
        .insertOnConflictUpdate(
          AppointmentCutoversCompanion.insert(
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
      '$_mirror.$userId',
      jsonEncode({'version': 1, 'checksum': checksum, 'count': records.length}),
    );
    return true;
  }
}

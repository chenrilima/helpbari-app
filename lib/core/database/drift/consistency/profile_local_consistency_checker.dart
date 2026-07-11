import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/profile_legacy_service.dart';

class ProfileLocalConsistencyChecker {
  const ProfileLocalConsistencyChecker({
    required this.database,
    required this.storage,
  });
  final AppDatabase database;
  final LocalStorageService storage;

  Future<ProfileConsistencyReport> check(String userId) async {
    final service = ProfileLegacyService(database: database, storage: storage);
    final migration = await service.migrate();
    final cutover = await service.ensureUserAndAttemptCutover(userId);
    return ProfileConsistencyReport(
      isConsistent:
          migration.invalid == 0 && cutover.blockedReason != 'not_converged',
      invalidLegacyRecords: migration.invalid,
      blockedReason: cutover.blockedReason,
    );
  }
}

class ProfileConsistencyReport {
  const ProfileConsistencyReport({
    required this.isConsistent,
    required this.invalidLegacyRecords,
    this.blockedReason,
  });
  final bool isConsistent;
  final int invalidLegacyRecords;
  final String? blockedReason;
}

import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import '../migrations/profile_legacy_service.dart';

class ProfileCutoverService {
  const ProfileCutoverService({required this.database, required this.storage});
  final AppDatabase database;
  final LocalStorageService storage;
  Future<ProfileCutoverResult> attempt(String userId) => ProfileLegacyService(
    database: database,
    storage: storage,
  ).ensureUserAndAttemptCutover(userId);
  static bool isCompletedMirrorFor(
    LocalStorageService storage,
    String userId,
  ) => storage.getString('core.profile.cutover.v1.$userId') != null;
}

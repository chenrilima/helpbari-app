import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/drift_profile_local_datasource.dart';
import '../datasources/local_profile_datasource.dart';

class DriftPrimaryProfileRepository implements ProfileRepository {
  const DriftPrimaryProfileRepository({
    required this.drift,
    required this.fallback,
    required this.ensureCutover,
    required this.hasCutoverMirror,
  });
  final Future<DriftProfileLocalDatasource> Function() drift;
  final LocalProfileDatasource fallback;
  final Future<void> Function() ensureCutover;
  final bool Function() hasCutoverMirror;

  Future<DriftProfileLocalDatasource> _resolve() async {
    final value = await drift();
    await ensureCutover();
    return value;
  }

  @override
  Future<Profile?> getProfile() async {
    try {
      return (await (await _resolve()).getProfile())?.toEntity();
    } catch (error) {
      if (hasCutoverMirror()) rethrow;
      AppLogger.info(
        'Profile Drift unavailable before cutover (${error.runtimeType}).',
      );
      return (await fallback.getProfile())?.toEntity();
    }
  }

  @override
  Future<void> saveProfile(Profile profile) async =>
      (await _resolve()).save(profile);
  @override
  Future<void> updateProfile(Profile profile) async =>
      (await _resolve()).save(profile);
  @override
  Future<void> deleteProfile(Profile profile) async =>
      (await _resolve()).softDelete(profile.id);
}

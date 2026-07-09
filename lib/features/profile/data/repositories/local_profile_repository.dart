import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_profile_datasource.dart';
import '../dtos/profile_dto.dart';

class LocalProfileRepository implements ProfileRepository {
  const LocalProfileRepository(this._datasource);

  final LocalProfileDatasource _datasource;

  @override
  Future<Profile?> getProfile() async {
    final dto = await _datasource.getProfile();

    return dto?.toEntity();
  }

  @override
  Future<void> saveProfile(Profile profile) {
    return _datasource.save(
      ProfileDto.fromEntity(profile, now: DateTime.now()),
    );
  }

  @override
  Future<void> updateProfile(Profile profile) {
    return _datasource.save(
      ProfileDto.fromEntity(profile, now: DateTime.now()),
    );
  }

  @override
  Future<void> deleteProfile(Profile profile) {
    return _datasource.delete(profile.id);
  }
}

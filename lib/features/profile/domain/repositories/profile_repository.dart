import '../entities/entities.dart';

abstract interface class ProfileRepository {
  Future<Profile?> getProfile();

  Future<void> saveProfile(Profile profile);

  Future<void> updateProfile(Profile profile);

  Future<void> deleteProfile(Profile profile);
}

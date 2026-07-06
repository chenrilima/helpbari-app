import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeProfileRepository implements ProfileRepository {
  Profile? _profile;

  @override
  Future<Profile?> getProfile() async {
    return _profile;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    _profile = profile;
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    _profile = profile;
  }

  @override
  Future<void> deleteProfile(Profile profile) async {
    if (_profile?.id == profile.id) {
      _profile = null;
    }
  }
}

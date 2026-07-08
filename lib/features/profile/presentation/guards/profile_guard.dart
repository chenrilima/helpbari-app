import '../../../profile/domain/entities/entities.dart';

class ProfileGuard {
  const ProfileGuard._();

  static bool isProfileCompleted(Profile? profile) {
    return profile != null;
  }
}

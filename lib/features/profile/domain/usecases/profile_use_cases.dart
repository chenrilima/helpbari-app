import 'delete_profile_use_case.dart';
import 'get_profile_use_case.dart';
import 'save_profile_use_case.dart';
import 'update_profile_use_case.dart';

class ProfileUseCases {
  const ProfileUseCases({
    required this.getProfile,
    required this.saveProfile,
    required this.updateProfile,
    required this.deleteProfile,
  });

  final GetProfileUseCase getProfile;
  final SaveProfileUseCase saveProfile;
  final UpdateProfileUseCase updateProfile;
  final DeleteProfileUseCase deleteProfile;
}

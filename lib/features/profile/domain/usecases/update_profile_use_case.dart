import '../entities/entities.dart';
import '../repositories/repositories.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call(Profile profile) {
    return _repository.updateProfile(profile);
  }
}

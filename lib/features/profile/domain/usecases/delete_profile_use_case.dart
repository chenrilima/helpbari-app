import '../entities/entities.dart';
import '../repositories/repositories.dart';

class DeleteProfileUseCase {
  const DeleteProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call(Profile profile) {
    return _repository.deleteProfile(profile);
  }
}

import '../entities/entities.dart';
import '../repositories/repositories.dart';

class SaveProfileUseCase {
  const SaveProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<void> call(Profile profile) {
    return _repository.saveProfile(profile);
  }
}

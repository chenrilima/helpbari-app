import '../entities/entities.dart';
import '../repositories/repositories.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Profile?> call() {
    return _repository.getProfile();
  }
}

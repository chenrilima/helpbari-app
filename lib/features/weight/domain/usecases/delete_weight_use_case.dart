import '../repositories/repositories.dart';

class DeleteWeightUseCase {
  const DeleteWeightUseCase(this._repository);

  final WeightRepository _repository;

  Future<void> call(String id) {
    return _repository.delete(id);
  }
}

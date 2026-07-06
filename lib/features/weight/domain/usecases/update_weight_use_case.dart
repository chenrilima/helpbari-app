import '../entities/entities.dart';
import '../repositories/repositories.dart';

class UpdateWeightUseCase {
  const UpdateWeightUseCase(this._repository);

  final WeightRepository _repository;

  Future<void> call(WeightRecord record) {
    return _repository.update(record);
  }
}

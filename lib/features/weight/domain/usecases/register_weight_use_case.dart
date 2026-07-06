import '../entities/entities.dart';
import '../repositories/repositories.dart';

class RegisterWeightUseCase {
  const RegisterWeightUseCase(this._repository);

  final WeightRepository _repository;

  Future<void> call(WeightRecord record) {
    return _repository.register(record);
  }
}

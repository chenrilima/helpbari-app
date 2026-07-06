import '../entities/entities.dart';
import '../repositories/repositories.dart';

class GetWeightHistoryUseCase {
  const GetWeightHistoryUseCase(this._repository);

  final WeightRepository _repository;

  Future<List<WeightRecord>> call() {
    return _repository.getHistory();
  }
}

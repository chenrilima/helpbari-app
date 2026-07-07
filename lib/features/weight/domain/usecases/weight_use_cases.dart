import '../entities/entities.dart';
import '../models/weight_summary.dart';
import '../repositories/weight_repository.dart';

class WeightUseCases {
  const WeightUseCases(this._repository);

  final WeightRepository _repository;

  Future<List<WeightRecord>> getHistory() {
    return _repository.getHistory();
  }

  Future<void> register(WeightRecord record) {
    return _repository.register(record);
  }

  Future<void> update(WeightRecord record) {
    return _repository.update(record);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<WeightSummary> getSummary() async {
    final history = await _repository.getHistory();

    return WeightSummary(
      latestRecord: history.isEmpty ? null : history.first,
      hasRecords: history.isNotEmpty,
    );
  }
}

import '../entities/entities.dart';
import '../models/weight_summary.dart';
import '../repositories/weight_repository.dart';

class WeightUseCases {
  const WeightUseCases(this._repository);

  final WeightRepository _repository;

  Future<List<WeightRecord>> getHistory() {
    return _repository.getHistory();
  }

  Future<List<WeightRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    int limit = 500,
  }) {
    final repository = _repository;
    if (repository is! WeightRangeRepository) {
      throw StateError('Consulta de peso por intervalo indisponível.');
    }
    return (repository as WeightRangeRepository).getByPeriod(
      startInclusive,
      endExclusive,
      limit: limit,
    );
  }

  Future<WeightRecord?> getLatest() {
    final repository = _repository;
    if (repository is! WeightRangeRepository) {
      throw StateError('Consulta do peso mais recente indisponível.');
    }
    return (repository as WeightRangeRepository).getLatest();
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

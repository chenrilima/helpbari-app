import '../../../../core/services/clock_service.dart';
import '../entities/entities.dart';
import '../repositories/water_repository.dart';

class WaterUseCases {
  const WaterUseCases(this._repository, this._clock);

  final WaterRepository _repository;
  final ClockService _clock;

  Future<void> create(WaterRecord record) {
    return _repository.create(record);
  }

  Future<void> update(WaterRecord record) {
    return _repository.update(record);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<List<WaterRecord>> getHistory() {
    return _repository.getHistory();
  }

  Future<int> getTodayTotalInMl() async {
    final history = await _repository.getHistory();

    final today = _clock.now();

    return history
        .where(
          (record) =>
              record.recordedAt.year == today.year &&
              record.recordedAt.month == today.month &&
              record.recordedAt.day == today.day,
        )
        .fold<int>(0, (total, record) => total + record.amount.valueInMl);
  }
}

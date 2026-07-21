import '../entities/entities.dart';

abstract interface class WaterRepository {
  Future<List<WaterRecord>> getHistory();

  Future<void> create(WaterRecord record);

  Future<void> update(WaterRecord record);

  Future<void> delete(String id);
}

abstract interface class WaterRangeRepository {
  Future<List<WaterRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  });
}

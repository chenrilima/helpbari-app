import '../entities/entities.dart';

abstract interface class WeightRepository {
  Future<List<WeightRecord>> getHistory();

  Future<void> register(WeightRecord record);

  Future<void> update(WeightRecord record);

  Future<void> delete(String id);
}

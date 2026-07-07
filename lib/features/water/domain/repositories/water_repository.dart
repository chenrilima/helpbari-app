import '../entities/entities.dart';

abstract interface class WaterRepository {
  Future<void> save(WaterRecord record);

  Future<List<WaterRecord>> getHistory();
}

import '../../domain/entities/entities.dart';
import '../../domain/repositories/water_repository.dart';

class FakeWaterRepository implements WaterRepository {
  final List<WaterRecord> _records = [];

  @override
  Future<List<WaterRecord>> getHistory() async {
    final records = [..._records];

    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return List.unmodifiable(records);
  }

  @override
  Future<void> save(WaterRecord record) async {
    _records.add(record);
  }
}

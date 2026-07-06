import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeWeightRepository implements WeightRepository {
  final List<WeightRecord> _records = [];

  @override
  Future<List<WeightRecord>> getHistory() async {
    final records = [..._records];

    records.sort((a, b) => b.recordedAt.value.compareTo(a.recordedAt.value));

    return List.unmodifiable(records);
  }

  @override
  Future<void> register(WeightRecord record) async {
    _records.add(record);
  }

  @override
  Future<void> update(WeightRecord record) async {
    final index = _records.indexWhere((e) => e.id == record.id);

    if (index == -1) return;

    _records[index] = record;
  }

  @override
  Future<void> delete(String id) async {
    _records.removeWhere((e) => e.id == id);
  }
}

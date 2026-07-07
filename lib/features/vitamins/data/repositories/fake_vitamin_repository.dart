import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeVitaminRepository implements VitaminRepository {
  final List<Vitamin> _vitamins = [];

  @override
  Future<List<Vitamin>> getAll() async {
    final vitamins = [..._vitamins];

    vitamins.sort((a, b) {
      final hourComparison = a.scheduleTime.hour.compareTo(b.scheduleTime.hour);

      if (hourComparison != 0) {
        return hourComparison;
      }

      return a.scheduleTime.minute.compareTo(b.scheduleTime.minute);
    });

    return List.unmodifiable(vitamins);
  }

  @override
  Future<void> save(Vitamin vitamin) async {
    _vitamins.add(vitamin);
  }

  @override
  Future<void> update(Vitamin vitamin) async {
    final index = _vitamins.indexWhere((item) => item.id == vitamin.id);

    if (index == -1) return;

    _vitamins[index] = vitamin;
  }

  @override
  Future<void> delete(String id) async {
    _vitamins.removeWhere((item) => item.id == id);
  }
}

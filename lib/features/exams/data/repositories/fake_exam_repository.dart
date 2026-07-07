import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeExamRepository implements ExamRepository {
  final List<Exam> _items = [];

  @override
  Future<List<Exam>> getAll() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> save(Exam item) async {
    _items.add(item);
  }

  @override
  Future<void> update(Exam item) async {
    final index = _items.indexWhere((element) => element.id == item.id);

    if (index == -1) return;

    _items[index] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

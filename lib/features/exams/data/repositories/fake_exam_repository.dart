import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeExamRepository implements ExamRepository {
  final List<Exam> _exams = [];

  @override
  Future<List<Exam>> getAll() async {
    final exams = [..._exams];

    exams.sort((a, b) => b.examDate.value.compareTo(a.examDate.value));

    return List.unmodifiable(exams);
  }

  @override
  Future<void> save(Exam exam) async {
    _exams.add(exam);
  }

  @override
  Future<void> update(Exam exam) async {
    final index = _exams.indexWhere((item) => item.id == exam.id);

    if (index == -1) return;

    _exams[index] = exam;
  }

  @override
  Future<void> delete(String id) async {
    _exams.removeWhere((item) => item.id == id);
  }
}

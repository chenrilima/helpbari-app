import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class ExamUseCases {
  const ExamUseCases(this._repository);

  final ExamRepository _repository;

  Future<List<Exam>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Exam exam) {
    return _repository.save(exam);
  }

  Future<void> update(Exam exam) {
    return _repository.update(exam);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<ExamSummary> getSummary() async {
    final exams = await _repository.getAll();

    return ExamSummary(
      latestExam: exams.isEmpty ? null : exams.first,
      hasExams: exams.isNotEmpty,
    );
  }
}

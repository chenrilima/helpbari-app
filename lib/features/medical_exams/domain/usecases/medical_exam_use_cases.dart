import '../entities/entities.dart';
import '../repositories/medical_exam_repository.dart';

class MedicalExamUseCases {
  const MedicalExamUseCases(this._repository);

  final MedicalExamRepository _repository;

  Future<List<MedicalExam>> getHistory() => _repository.getHistory();
  Future<List<MedicalExam>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    int limit = 500,
  }) {
    final repository = _repository;
    if (repository is! MedicalExamRangeRepository) {
      throw StateError('Consulta de exames por intervalo indisponível.');
    }
    return (repository as MedicalExamRangeRepository).getByPeriod(
      startInclusive,
      endExclusive,
      limit: limit,
    );
  }

  Future<MedicalExam?> getById(String id) => _repository.getById(id);
  Future<void> save(MedicalExam exam) => _repository.save(exam);
  Future<void> delete(String id) => _repository.delete(id);
}

import '../entities/entities.dart';
import '../repositories/repositories.dart';

class ExamUseCases {
  const ExamUseCases(this._repository);

  final ExamRepository _repository;

  Future<List<Exam>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Exam item) {
    return _repository.save(item);
  }

  Future<void> update(Exam item) {
    return _repository.update(item);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }
}

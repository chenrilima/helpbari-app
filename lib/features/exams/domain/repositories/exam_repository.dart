import '../entities/entities.dart';

abstract interface class ExamRepository {
  Future<List<Exam>> getAll();

  Future<void> save(Exam exam);

  Future<void> update(Exam exam);

  Future<void> delete(String id);
}

import '../entities/entities.dart';

abstract interface class ExamRepository {
  Future<List<Exam>> getAll();

  Future<void> save(Exam item);

  Future<void> update(Exam item);

  Future<void> delete(String id);
}

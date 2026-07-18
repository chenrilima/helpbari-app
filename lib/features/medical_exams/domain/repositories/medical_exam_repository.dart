import '../entities/entities.dart';

abstract interface class MedicalExamRepository {
  Future<List<MedicalExam>> getHistory();
  Future<MedicalExam?> getById(String id);
  Future<void> save(MedicalExam exam);
  Future<void> delete(String id);
}

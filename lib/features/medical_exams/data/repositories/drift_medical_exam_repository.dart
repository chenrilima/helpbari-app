import '../../domain/entities/entities.dart';
import '../../domain/repositories/medical_exam_repository.dart';
import '../datasources/drift_medical_exam_local_datasource.dart';

class DriftMedicalExamRepository implements MedicalExamRepository {
  const DriftMedicalExamRepository(this._local);

  final Future<DriftMedicalExamLocalDatasource> Function() _local;

  @override
  Future<List<MedicalExam>> getHistory() async => (await _local()).getHistory();

  @override
  Future<MedicalExam?> getById(String id) async => (await _local()).getById(id);

  @override
  Future<void> save(MedicalExam exam) async => (await _local()).save(exam);

  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}

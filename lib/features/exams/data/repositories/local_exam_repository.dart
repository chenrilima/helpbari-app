import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_exam_datasource.dart';
import '../dtos/exam_dto.dart';

class LocalExamRepository implements ExamRepository {
  const LocalExamRepository(this._datasource);

  final LocalExamDatasource _datasource;

  @override
  Future<List<Exam>> getAll() async {
    final exams = await _datasource.getAll();

    return exams.map((exam) => exam.toEntity()).toList();
  }

  @override
  Future<void> save(Exam exam) {
    return _datasource.save(ExamDto.fromEntity(exam, now: DateTime.now()));
  }

  @override
  Future<void> update(Exam exam) {
    return _datasource.save(ExamDto.fromEntity(exam, now: DateTime.now()));
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}

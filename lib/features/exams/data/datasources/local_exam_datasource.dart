import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/exam_dto.dart';

class LocalExamDatasource {
  const LocalExamDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'exams';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<ExamDto>> getAll() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a.data['examDate'] as String);
        final bDate = DateTime.parse(b.data['examDate'] as String);

        return bDate.compareTo(aDate);
      });

    return activeRecords.map(ExamDto.fromRecord).toList();
  }

  Future<void> save(ExamDto exam) async {
    final previous = await _database.getById(collection, exam.id);
    final dto = ExamDto.fromEntity(
      exam.toEntity(),
      now: _clock.now(),
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
  }

  Future<void> delete(String id) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;

    final now = _clock.now();
    await _database.upsert(
      collection,
      previous.copyWith(
        metadata: previous.metadata.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      ),
    );
  }
}

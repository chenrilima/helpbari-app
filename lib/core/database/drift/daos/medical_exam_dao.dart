import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/medical_exam_results.dart';
import '../tables/medical_exams.dart';

part 'medical_exam_dao.g.dart';

@DriftAccessor(tables: [MedicalExams, MedicalExamResults])
class MedicalExamDao extends DatabaseAccessor<AppDatabase>
    with _$MedicalExamDaoMixin {
  MedicalExamDao(super.attachedDatabase);

  Future<List<MedicalExam>> getActiveExamsByUser(String userId) =>
      (select(medicalExams)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.performedAt)]))
          .get();

  Future<MedicalExam?> getExamByUserAndId(String userId, String id) =>
      (select(medicalExams)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<MedicalExamResult>> getActiveResultsByExam(
    String userId,
    String examId,
  ) =>
      (select(medicalExamResults)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.medicalExamId.equals(examId) &
                  row.deletedAt.isNull(),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<MedicalExamResult>> getResultsByExamIncludingDeleted(
    String userId,
    String examId,
  ) =>
      (select(medicalExamResults)
            ..where(
              (row) =>
                  row.userId.equals(userId) & row.medicalExamId.equals(examId),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<MedicalExam>> getPendingExamsForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(medicalExams)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<List<MedicalExamResult>> getPendingResultsForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(medicalExamResults)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsertExam(MedicalExamsCompanion exam) =>
      into(medicalExams).insertOnConflictUpdate(exam);

  Future<void> upsertResult(MedicalExamResultsCompanion result) =>
      into(medicalExamResults).insertOnConflictUpdate(result);

  Future<void> replaceResults(
    String userId,
    String examId,
    List<MedicalExamResultsCompanion> next,
  ) => transaction(() async {
    await (delete(medicalExamResults)..where(
          (row) => row.userId.equals(userId) & row.medicalExamId.equals(examId),
        ))
        .go();
    if (next.isNotEmpty) {
      await batch((batch) => batch.insertAll(medicalExamResults, next));
    }
  });

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId, String repositoryKey) async {
    final row =
        await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
              (cursor) =>
                  cursor.userId.equals(userId) &
                  cursor.repositoryKey.equals(repositoryKey),
            ))
            .getSingleOrNull();
    return row?.lastPullAt;
  }

  Future<void> saveCursor(
    String userId,
    String repositoryKey,
    DateTime completedAt,
  ) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: repositoryKey,
          lastPullAt: Value(completedAt),
          lastPushAt: Value(completedAt),
          lastSyncAt: Value(completedAt),
          status: const Value('success'),
        ),
      );
}

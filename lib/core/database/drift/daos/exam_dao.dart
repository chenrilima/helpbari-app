import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exam_records.dart';
part 'exam_dao.g.dart';

@DriftAccessor(tables: [ExamRecords])
class ExamDao extends DatabaseAccessor<AppDatabase> with _$ExamDaoMixin {
  ExamDao(super.attachedDatabase);
  Future<List<ExamRecord>> getActiveByUser(String userId) =>
      (select(examRecords)
            ..where((r) => r.userId.equals(userId) & r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.examDate)]))
          .get();
  Future<ExamRecord?> getByUserAndId(String userId, String id) => (select(
    examRecords,
  )..where((r) => r.userId.equals(userId) & r.id.equals(id))).getSingleOrNull();
  Future<List<ExamRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(examRecords)
          ..where(
            (r) => r.userId.equals(userId) & r.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.updatedAt)]))
        .get();
  }

  Future<void> upsert(ExamRecordsCompanion value) =>
      into(examRecords).insertOnConflictUpdate(value);
  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);
  Future<DateTime?> getLastPullAt(String userId, String key) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (r) => r.userId.equals(userId) & r.repositoryKey.equals(key),
              ))
              .getSingleOrNull())
          ?.lastPullAt;
  Future<void> saveCursor(String userId, String key, DateTime at) =>
      attachedDatabase
          .into(attachedDatabase.syncCursors)
          .insertOnConflictUpdate(
            SyncCursorsCompanion.insert(
              userId: userId,
              repositoryKey: key,
              lastPullAt: Value(at),
              lastPushAt: Value(at),
              lastSyncAt: Value(at),
              status: const Value('success'),
            ),
          );
}

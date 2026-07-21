import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/weight_records.dart';

part 'weight_dao.g.dart';

@DriftAccessor(tables: [WeightRecords])
class WeightDao extends DatabaseAccessor<AppDatabase> with _$WeightDaoMixin {
  WeightDao(super.attachedDatabase);

  Future<List<WeightRecord>> getActiveByUser(String userId) =>
      (select(weightRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)]))
          .get();

  Future<List<WeightRecord>> getActiveByUserInRange(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) =>
      (select(weightRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.deletedAt.isNull() &
                  row.recordedAt.isBiggerOrEqualValue(startInclusive) &
                  row.recordedAt.isSmallerThanValue(endExclusive),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)])
            ..limit(limit))
          .get();

  Future<WeightRecord?> getLatestActiveByUser(String userId) =>
      (select(weightRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<WeightRecord?> getByUserAndId(String userId, String id) =>
      (select(weightRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<WeightRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(weightRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsert(WeightRecordsCompanion record) =>
      into(weightRecords).insertOnConflictUpdate(record);

  Future<void> upsertAll(Iterable<WeightRecordsCompanion> records) => batch(
    (batch) => batch.insertAllOnConflictUpdate(weightRecords, records.toList()),
  );

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId, String repositoryKey) async {
    final row =
        await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.repositoryKey.equals(repositoryKey),
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

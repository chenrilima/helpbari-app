import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/water_records.dart';

part 'water_dao.g.dart';

@DriftAccessor(tables: [WaterRecords])
class WaterDao extends DatabaseAccessor<AppDatabase> with _$WaterDaoMixin {
  WaterDao(super.attachedDatabase);

  Future<List<WaterRecord>> getActiveByUser(String userId) {
    return (select(waterRecords)
          ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
          ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)]))
        .get();
  }

  Future<List<WaterRecord>> getActiveByUserInRange(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) =>
      (select(waterRecords)
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

  Future<WaterRecord?> getByUserAndId(String userId, String id) {
    return (select(waterRecords)
          ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WaterRecord>> getPendingByUser(String userId) {
    return (select(waterRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  /// Anonymous legacy records are intentionally excluded from sync reads.
  Future<List<WaterRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return getPendingByUser(userId);
  }

  Future<void> upsert(WaterRecordsCompanion record) {
    return into(waterRecords).insertOnConflictUpdate(record);
  }

  Future<void> upsertAll(Iterable<WaterRecordsCompanion> records) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(waterRecords, records.toList());
    });
  }

  Future<void> deleteByUserAndId(String userId, String id) {
    return (delete(
      waterRecords,
    )..where((row) => row.userId.equals(userId) & row.id.equals(id))).go();
  }

  Future<T> inTransaction<T>(Future<T> Function() action) {
    return transaction(action);
  }

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
  ) {
    return attachedDatabase
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
}

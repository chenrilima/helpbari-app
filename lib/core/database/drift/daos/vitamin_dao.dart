import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/vitamin_records.dart';

part 'vitamin_dao.g.dart';

@DriftAccessor(tables: [VitaminRecords])
class VitaminDao extends DatabaseAccessor<AppDatabase> with _$VitaminDaoMixin {
  VitaminDao(super.attachedDatabase);

  Future<List<VitaminRecord>> getActiveByUser(String userId) =>
      (select(vitaminRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([
              (row) => OrderingTerm.asc(row.scheduleHour),
              (row) => OrderingTerm.asc(row.scheduleMinute),
            ]))
          .get();
  Future<VitaminRecord?> getByUserAndId(String userId, String id) =>
      (select(vitaminRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<List<VitaminRecord>> getPendingForSync(String userId) =>
      userId == 'anonymous'
      ? Future.value(const [])
      : (select(vitaminRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.syncStatus.isNotValue('synced'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
            .get();
  Future<void> upsert(VitaminRecordsCompanion value) =>
      into(vitaminRecords).insertOnConflictUpdate(value);
  Future<void> upsertAll(Iterable<VitaminRecordsCompanion> values) => batch(
    (batch) => batch.insertAllOnConflictUpdate(vitaminRecords, values.toList()),
  );
  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);
  Future<DateTime?> getLastPullAt(String userId, String key) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (row) =>
                    row.userId.equals(userId) & row.repositoryKey.equals(key),
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

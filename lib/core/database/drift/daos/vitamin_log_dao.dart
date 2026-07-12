import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/vitamin_log_records.dart';

part 'vitamin_log_dao.g.dart';

@DriftAccessor(tables: [VitaminLogRecords])
class VitaminLogDao extends DatabaseAccessor<AppDatabase>
    with _$VitaminLogDaoMixin {
  VitaminLogDao(super.attachedDatabase);

  Future<List<VitaminLogRecord>> getByPeriod(
    String userId,
    DateTime start,
    DateTime end,
  ) =>
      (select(vitaminLogRecords)
            ..where(
              (row) =>
                  row.userId.equals(userId) &
                  row.deletedAt.isNull() &
                  row.logDate.isBiggerOrEqualValue(start) &
                  row.logDate.isSmallerOrEqualValue(end),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.logDate)]))
          .get();
  Future<VitaminLogRecord?> getByVitaminAndDate(
    String userId,
    String vitaminId,
    DateTime date,
  ) =>
      (select(vitaminLogRecords)..where(
            (row) =>
                row.userId.equals(userId) &
                row.vitaminId.equals(vitaminId) &
                row.logDate.equals(date),
          ))
          .getSingleOrNull();
  Future<VitaminLogRecord?> getByUserAndId(String userId, String id) =>
      (select(vitaminLogRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();
  Future<List<VitaminLogRecord>> getPendingForSync(String userId) =>
      userId == 'anonymous'
      ? Future.value(const [])
      : (select(vitaminLogRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.syncStatus.isNotValue('synced'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
            .get();
  Future<void> upsert(VitaminLogRecordsCompanion value) =>
      into(vitaminLogRecords).insertOnConflictUpdate(value);
  Future<void> upsertAll(Iterable<VitaminLogRecordsCompanion> values) => batch(
    (batch) =>
        batch.insertAllOnConflictUpdate(vitaminLogRecords, values.toList()),
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

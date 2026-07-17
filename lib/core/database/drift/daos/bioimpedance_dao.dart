import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/bioimpedance_records.dart';

part 'bioimpedance_dao.g.dart';

@DriftAccessor(tables: [BioimpedanceRecords])
class BioimpedanceDao extends DatabaseAccessor<AppDatabase>
    with _$BioimpedanceDaoMixin {
  BioimpedanceDao(super.attachedDatabase);

  Future<List<BioimpedanceRecord>> getActiveByUser(String userId) =>
      (select(bioimpedanceRecords)
            ..where((row) => row.userId.equals(userId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.measuredAt)]))
          .get();

  Future<BioimpedanceRecord?> getByUserAndId(String userId, String id) =>
      (select(bioimpedanceRecords)
            ..where((row) => row.userId.equals(userId) & row.id.equals(id)))
          .getSingleOrNull();

  Future<List<BioimpedanceRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(bioimpedanceRecords)
          ..where(
            (row) =>
                row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.updatedAt)]))
        .get();
  }

  Future<void> upsert(BioimpedanceRecordsCompanion record) =>
      into(bioimpedanceRecords).insertOnConflictUpdate(record);

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

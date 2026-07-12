import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/medication_records.dart';
part 'medication_dao.g.dart';

@DriftAccessor(tables: [MedicationRecords])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.attachedDatabase);
  Future<List<MedicationRecord>> getActiveByUser(String userId) =>
      (select(medicationRecords)
            ..where((r) => r.userId.equals(userId) & r.deletedAt.isNull())
            ..orderBy([
              (r) => OrderingTerm.asc(r.scheduleHour),
              (r) => OrderingTerm.asc(r.scheduleMinute),
            ]))
          .get();
  Future<MedicationRecord?> getByUserAndId(String userId, String id) => (select(
    medicationRecords,
  )..where((r) => r.userId.equals(userId) & r.id.equals(id))).getSingleOrNull();
  Future<List<MedicationRecord>> getPendingForSync(String userId) =>
      userId == 'anonymous'
      ? Future.value(const [])
      : (select(medicationRecords)
              ..where(
                (r) =>
                    r.userId.equals(userId) & r.syncStatus.isNotValue('synced'),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.updatedAt)]))
            .get();
  Future<void> upsert(MedicationRecordsCompanion value) =>
      into(medicationRecords).insertOnConflictUpdate(value);
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

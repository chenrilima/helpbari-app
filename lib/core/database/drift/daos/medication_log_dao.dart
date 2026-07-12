import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/medication_log_records.dart';
part 'medication_log_dao.g.dart';

@DriftAccessor(tables: [MedicationLogRecords])
class MedicationLogDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationLogDaoMixin {
  MedicationLogDao(super.attachedDatabase);
  Future<List<MedicationLogRecord>> getByPeriod(
    String userId,
    DateTime start,
    DateTime end,
  ) =>
      (select(medicationLogRecords)
            ..where(
              (r) =>
                  r.userId.equals(userId) &
                  r.deletedAt.isNull() &
                  r.logDate.isBiggerOrEqualValue(start) &
                  r.logDate.isSmallerOrEqualValue(end),
            )
            ..orderBy([(r) => OrderingTerm.desc(r.logDate)]))
          .get();
  Future<MedicationLogRecord?> getByMedicationAndDate(
    String userId,
    String medicationId,
    DateTime date,
  ) =>
      (select(medicationLogRecords)..where(
            (r) =>
                r.userId.equals(userId) &
                r.medicationId.equals(medicationId) &
                r.logDate.equals(date),
          ))
          .getSingleOrNull();
  Future<MedicationLogRecord?> getByUserAndId(String userId, String id) =>
      (select(medicationLogRecords)
            ..where((r) => r.userId.equals(userId) & r.id.equals(id)))
          .getSingleOrNull();
  Future<List<MedicationLogRecord>> getPendingForSync(String userId) =>
      userId == 'anonymous'
      ? Future.value(const [])
      : (select(medicationLogRecords)
              ..where(
                (r) =>
                    r.userId.equals(userId) & r.syncStatus.isNotValue('synced'),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.updatedAt)]))
            .get();
  Future<void> upsert(MedicationLogRecordsCompanion value) =>
      into(medicationLogRecords).insertOnConflictUpdate(value);
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

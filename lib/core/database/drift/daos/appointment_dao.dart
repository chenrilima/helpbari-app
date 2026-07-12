import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/appointment_records.dart';
part 'appointment_dao.g.dart';

@DriftAccessor(tables: [AppointmentRecords])
class AppointmentDao extends DatabaseAccessor<AppDatabase>
    with _$AppointmentDaoMixin {
  AppointmentDao(super.attachedDatabase);
  Future<List<AppointmentRecord>> getActiveByUser(String userId) =>
      (select(appointmentRecords)
            ..where((r) => r.userId.equals(userId) & r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.asc(r.appointmentAt)]))
          .get();
  Future<AppointmentRecord?> getByUserAndId(String userId, String id) =>
      (select(appointmentRecords)
            ..where((r) => r.userId.equals(userId) & r.id.equals(id)))
          .getSingleOrNull();
  Future<List<AppointmentRecord>> getPendingForSync(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(appointmentRecords)
          ..where(
            (r) => r.userId.equals(userId) & r.syncStatus.isNotValue('synced'),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.updatedAt)]))
        .get();
  }

  Future<void> upsert(AppointmentRecordsCompanion value) =>
      into(appointmentRecords).insertOnConflictUpdate(value);
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

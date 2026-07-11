import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/profile_records.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [ProfileRecords])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.attachedDatabase);

  Future<ProfileRecord?> getByUser(String userId) => (select(
    profileRecords,
  )..where((r) => r.userId.equals(userId))).getSingleOrNull();

  Future<List<ProfileRecord>> getPending(String userId) =>
      (select(profileRecords)..where(
            (r) => r.userId.equals(userId) & r.syncStatus.isNotValue('synced'),
          ))
          .get();

  Future<void> upsert(ProfileRecordsCompanion value) =>
      into(profileRecords).insertOnConflictUpdate(value);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (r) =>
                    r.userId.equals(userId) & r.repositoryKey.equals('profile'),
              ))
              .getSingleOrNull())
          ?.lastPullAt;

  Future<void> saveCursor(String userId, DateTime at) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: 'profile',
          lastPullAt: Value(at),
          lastPushAt: Value(at),
          lastSyncAt: Value(at),
          status: const Value('success'),
        ),
      );
}

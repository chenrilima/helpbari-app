import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/settings_records.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [SettingsRecords])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<SettingsRecord?> getByUser(String userId) => (select(
    settingsRecords,
  )..where((row) => row.userId.equals(userId))).getSingleOrNull();

  Future<List<SettingsRecord>> getPending(String userId) {
    if (userId == 'anonymous') return Future.value(const []);
    return (select(settingsRecords)..where(
          (row) =>
              row.userId.equals(userId) & row.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<void> upsert(SettingsRecordsCompanion value) =>
      into(settingsRecords).insertOnConflictUpdate(value);

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      transaction(action);

  Future<DateTime?> getLastPullAt(String userId) async =>
      (await (attachedDatabase.select(attachedDatabase.syncCursors)..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.repositoryKey.equals('settings'),
              ))
              .getSingleOrNull())
          ?.lastPullAt;

  Future<void> saveCursor(String userId, DateTime at) => attachedDatabase
      .into(attachedDatabase.syncCursors)
      .insertOnConflictUpdate(
        SyncCursorsCompanion.insert(
          userId: userId,
          repositoryKey: 'settings',
          lastPullAt: Value(at),
          lastPushAt: Value(at),
          lastSyncAt: Value(at),
          status: const Value('success'),
        ),
      );
}

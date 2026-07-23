import 'package:drift/drift.dart';

import '../../sync/sync_version_store.dart';
import 'app_database.dart';

final class DriftSyncVersionStore implements SyncVersionStore {
  const DriftSyncVersionStore(this._database);

  final Future<AppDatabase> Function() _database;

  @override
  Future<int?> read({
    required String userId,
    required String repositoryKey,
    required String recordId,
  }) async {
    final database = await _database();
    final row =
        await (database.select(database.syncRecordVersions)..where(
              (value) =>
                  value.userId.equals(userId) &
                  value.repositoryKey.equals(repositoryKey) &
                  value.recordId.equals(recordId),
            ))
            .getSingleOrNull();
    return row?.serverRevision;
  }

  @override
  Future<void> write({
    required String userId,
    required String repositoryKey,
    required String recordId,
    required int serverRevision,
  }) async {
    final database = await _database();
    await database
        .into(database.syncRecordVersions)
        .insertOnConflictUpdate(
          SyncRecordVersionsCompanion.insert(
            userId: userId,
            repositoryKey: repositoryKey,
            recordId: recordId,
            serverRevision: serverRevision,
          ),
        );
  }
}

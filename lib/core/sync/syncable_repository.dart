import 'sync_error.dart';
import 'sync_operation.dart';

abstract interface class SyncableRepository {
  String get syncKey;

  Future<List<SyncOperation>> pendingOperations();

  Future<SyncOperation?> localOperationById(String recordId);

  Future<void> push(SyncOperation operation);

  Future<List<SyncOperation>> pull({DateTime? updatedAfter});

  Future<void> applyRemote(SyncOperation operation);

  Future<void> markSynced(String recordId, {required DateTime syncedAt});

  Future<void> markFailed(String recordId, SyncError error);
}

abstract interface class RepositorySyncCursor {
  Future<DateTime?> getLastPullAt();
  Future<void> saveSuccessfulSync(DateTime completedAt);
}

abstract interface class PagedPullSyncRepository {
  Stream<List<SyncOperation>> pullPages({
    DateTime? updatedAfter,
    int pageSize = 500,
  });
}

abstract interface class AtomicRemoteSyncRepository {
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  });
}

/// Mutable repositories use the last server-confirmed row revision as the
/// optimistic base. A mismatch must throw [SyncRevisionConflictException].
abstract interface class VersionedPushSyncRepository {
  Future<SyncOperation> pushVersioned(
    SyncOperation operation, {
    required int? baseRevision,
  });
}

final class SyncRevisionConflictException implements Exception {
  const SyncRevisionConflictException(this.remote);

  final SyncOperation remote;

  @override
  String toString() => 'Remote record revision advanced.';
}

/// Opts a repository out of destructive `updatedAt` conflict resolution.
/// Same-id payload equality/conflict remains the repository's responsibility.
abstract interface class AppendOnlySyncRepository {
  bool isAppendOnly(SyncOperation operation);
}

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

import 'sync_operation.dart';
import 'sync_status.dart';

class SyncStatusMapper {
  const SyncStatusMapper();

  SyncOperationType operationTypeFromStatus(SyncStatus status) {
    return switch (status) {
      SyncStatus.pendingCreate => SyncOperationType.create,
      SyncStatus.pendingUpdate => SyncOperationType.update,
      SyncStatus.pendingDelete => SyncOperationType.delete,
      SyncStatus.synced || SyncStatus.failed => SyncOperationType.update,
    };
  }

  SyncStatus statusFromOperationType(SyncOperationType type) {
    return switch (type) {
      SyncOperationType.create => SyncStatus.pendingCreate,
      SyncOperationType.update => SyncStatus.pendingUpdate,
      SyncOperationType.delete => SyncStatus.pendingDelete,
    };
  }
}

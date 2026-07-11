import '../services/clock_service.dart';
import 'sync_conflict.dart';
import 'sync_error.dart';
import 'sync_operation.dart';
import 'sync_result.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

class SyncEngine {
  const SyncEngine({
    required SyncStateRepository stateRepository,
    required ClockService clock,
    int maxRetries = 2,
  }) : _stateRepository = stateRepository,
       _clock = clock,
       _maxRetries = maxRetries;

  final SyncStateRepository _stateRepository;
  final ClockService _clock;
  final int _maxRetries;

  Future<SyncResult> sync({
    required Iterable<SyncableRepository> repositories,
    required String appVersion,
    required String? userId,
  }) async {
    final startedAt = _clock.now();
    final initialState = await _stateRepository.ensureState(
      appVersion: appVersion,
      userId: userId,
    );

    var pushed = 0;
    var pulled = 0;
    var deleted = 0;
    var repositoriesProcessed = 0;
    final conflicts = <SyncConflict>[];
    final errors = <SyncError>[];

    for (final repository in repositories) {
      repositoriesProcessed++;

      try {
        final pullResult = await _pullRemote(
          repository,
          updatedAfter: initialState.lastPullAt,
        );
        pulled += pullResult.pulled;
        deleted += pullResult.deleted;
        conflicts.addAll(pullResult.conflicts);
        errors.addAll(pullResult.errors);
      } catch (error, stackTrace) {
        errors.add(
          SyncError(
            repositoryKey: repository.syncKey,
            message: error.toString(),
            operation: 'pull',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }

      try {
        final pushResult = await _pushPending(repository);
        pushed += pushResult.pushed;
        deleted += pushResult.deleted;
        errors.addAll(pushResult.errors);
      } catch (error, stackTrace) {
        errors.add(
          SyncError(
            repositoryKey: repository.syncKey,
            message: error.toString(),
            operation: 'push',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    final completedAt = _clock.now();
    final result = SyncResult(
      startedAt: startedAt,
      completedAt: completedAt,
      repositoriesProcessed: repositoriesProcessed,
      pushed: pushed,
      pulled: pulled,
      deleted: deleted,
      conflicts: List.unmodifiable(conflicts),
      errors: List.unmodifiable(errors),
    );

    await _stateRepository.saveState(
      initialState.copyWith(
        phase: result.isSuccess ? SyncPhase.success : SyncPhase.failure,
        lastPullAt: result.isSuccess ? completedAt : initialState.lastPullAt,
        lastPushAt: result.isSuccess ? completedAt : initialState.lastPushAt,
        lastSyncAt: completedAt,
        lastResult: result,
        errorMessage: result.isSuccess ? null : errors.first.message,
        clearError: result.isSuccess,
      ),
    );

    return result;
  }

  Future<_PushResult> _pushPending(SyncableRepository repository) async {
    final operations = await repository.pendingOperations();
    var pushed = 0;
    var deleted = 0;
    final errors = <SyncError>[];

    for (final operation in operations) {
      final error = await _retry(
        repository: repository,
        operation: operation,
        action: 'push',
        callback: () => repository.push(operation),
      );

      if (error == null) {
        await repository.markSynced(operation.recordId, syncedAt: _clock.now());
        pushed++;
        if (operation.isDelete) deleted++;
      } else {
        await repository.markFailed(operation.recordId, error);
        errors.add(error);
      }
    }

    return _PushResult(pushed: pushed, deleted: deleted, errors: errors);
  }

  Future<_PullResult> _pullRemote(
    SyncableRepository repository, {
    required DateTime? updatedAfter,
  }) async {
    final remoteOperations = await repository.pull(updatedAfter: updatedAfter);
    var pulled = 0;
    var deleted = 0;
    final conflicts = <SyncConflict>[];
    final errors = <SyncError>[];

    for (final remote in remoteOperations) {
      try {
        final local = await repository.localOperationById(remote.recordId);
        var operationToApply = remote;

        if (local != null) {
          operationToApply = _resolveLatest(local, remote);
          conflicts.add(
            SyncConflict(
              repositoryKey: repository.syncKey,
              recordId: remote.recordId,
              local: local,
              remote: remote,
              winner: operationToApply,
            ),
          );
        }

        if (identical(operationToApply, remote)) {
          await repository.applyRemote(remote);
          await repository.markSynced(remote.recordId, syncedAt: _clock.now());
          pulled++;
          if (remote.isDelete) deleted++;
        }
      } catch (error, stackTrace) {
        errors.add(
          SyncError(
            repositoryKey: repository.syncKey,
            recordId: remote.recordId,
            message: error.toString(),
            operation: 'pull',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }

    return _PullResult(
      pulled: pulled,
      deleted: deleted,
      conflicts: conflicts,
      errors: errors,
    );
  }

  SyncOperation _resolveLatest(SyncOperation local, SyncOperation remote) {
    if (remote.updatedAt.isAfter(local.updatedAt)) return remote;
    return local;
  }

  Future<SyncError?> _retry({
    required SyncableRepository repository,
    required SyncOperation operation,
    required String action,
    required Future<void> Function() callback,
  }) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        await callback();
        return null;
      } catch (error, stackTrace) {
        if (attempt == _maxRetries) {
          return SyncError(
            repositoryKey: repository.syncKey,
            recordId: operation.recordId,
            message: error.toString(),
            operation: action,
            cause: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    return null;
  }
}

class _PushResult {
  const _PushResult({
    required this.pushed,
    required this.deleted,
    required this.errors,
  });

  final int pushed;
  final int deleted;
  final List<SyncError> errors;
}

class _PullResult {
  const _PullResult({
    required this.pulled,
    required this.deleted,
    required this.conflicts,
    required this.errors,
  });

  final int pulled;
  final int deleted;
  final List<SyncConflict> conflicts;
  final List<SyncError> errors;
}

import 'dart:async';

import '../services/clock_service.dart';
import 'sync_conflict.dart';
import 'sync_error.dart';
import 'sync_operation.dart';
import 'sync_result.dart';
import 'sync_session.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

class SyncEngine {
  const SyncEngine({
    required SyncStateRepository stateRepository,
    required ClockService clock,
    int maxRetries = 2,
    Duration operationTimeout = const Duration(seconds: 15),
    Duration retryBaseDelay = const Duration(milliseconds: 250),
  }) : _stateRepository = stateRepository,
       _clock = clock,
       _maxRetries = maxRetries,
       _operationTimeout = operationTimeout,
       _retryBaseDelay = retryBaseDelay;

  final SyncStateRepository _stateRepository;
  final ClockService _clock;
  final int _maxRetries;
  final Duration _operationTimeout;
  final Duration _retryBaseDelay;

  Future<SyncResult> sync({
    required Iterable<SyncableRepository> repositories,
    required String appVersion,
    required String? userId,
    SyncSessionToken? session,
  }) async {
    session?.ensureCurrent();
    final startedAt = _clock.now();
    final initialState = await _stateRepository.ensureState(
      appVersion: appVersion,
      userId: userId,
    );
    session?.ensureCurrent();

    var pushed = 0;
    var pulled = 0;
    var deleted = 0;
    var repositoriesProcessed = 0;
    final conflicts = <SyncConflict>[];
    final errors = <SyncError>[];
    final domainsChanged = <SyncDomain>{};

    if (userId == null || userId.isEmpty) {
      errors.add(
        const SyncError(
          repositoryKey: 'sync',
          message: 'Sincronização indisponível sem usuário autenticado.',
          operation: 'availability',
        ),
      );
    } else if (userId == 'dev-user' || userId == 'anonymous') {
      errors.add(
        const SyncError(
          repositoryKey: 'sync',
          message: 'Identidade local de desenvolvimento não pode sincronizar.',
          operation: 'identity',
        ),
      );
    } else if (repositories.isEmpty) {
      errors.add(
        const SyncError(
          repositoryKey: 'sync',
          message: 'Nenhum repositório de sincronização está disponível.',
          operation: 'availability',
        ),
      );
    }

    for (final repository
        in errors.isEmpty ? repositories : const <SyncableRepository>[]) {
      session?.ensureCurrent();
      repositoriesProcessed++;
      final updatedAfter = repository is RepositorySyncCursor
          ? await (repository as RepositorySyncCursor).getLastPullAt()
          : initialState.lastPullAt;

      try {
        final pullResult = await _pullRemote(
          repository,
          updatedAfter: updatedAfter,
          session: session,
        );
        pulled += pullResult.pulled;
        deleted += pullResult.deleted;
        conflicts.addAll(pullResult.conflicts);
        errors.addAll(pullResult.errors);
        if (pullResult.pulled > 0 || pullResult.deleted > 0) {
          domainsChanged.add(SyncDomain.fromRepositoryKey(repository.syncKey));
        }
      } on SyncSessionRevokedException {
        rethrow;
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
        final pushResult = await _pushPending(repository, session: session);
        pushed += pushResult.pushed;
        deleted += pushResult.deleted;
        errors.addAll(pushResult.errors);
        if (pushResult.pushed > 0 || pushResult.deleted > 0) {
          domainsChanged.add(SyncDomain.fromRepositoryKey(repository.syncKey));
        }
      } on SyncSessionRevokedException {
        rethrow;
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
      if (repository is RepositorySyncCursor &&
          !errors.any((error) => error.repositoryKey == repository.syncKey)) {
        session?.ensureCurrent();
        await (repository as RepositorySyncCursor).saveSuccessfulSync(
          _clock.now(),
        );
        session?.ensureCurrent();
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
      userId: userId,
      domainsChanged: Set.unmodifiable(domainsChanged),
      fullRefreshRequired: domainsChanged.contains(SyncDomain.unknown),
    );

    session?.ensureCurrent();
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
    session?.ensureCurrent();

    return result;
  }

  Future<_PushResult> _pushPending(
    SyncableRepository repository, {
    SyncSessionToken? session,
  }) async {
    session?.ensureCurrent();
    final operations = await repository.pendingOperations().timeout(
      _operationTimeout,
    );
    session?.ensureCurrent();
    var pushed = 0;
    var deleted = 0;
    final errors = <SyncError>[];

    for (final operation in operations) {
      session?.ensureCurrent();
      final error = await _retry(
        repository: repository,
        operation: operation,
        action: 'push',
        callback: () => repository.push(operation),
        session: session,
      );

      if (error == null) {
        session?.ensureCurrent();
        await repository.markSynced(operation.recordId, syncedAt: _clock.now());
        session?.ensureCurrent();
        pushed++;
        if (operation.isDelete) deleted++;
      } else {
        session?.ensureCurrent();
        await repository.markFailed(operation.recordId, error);
        session?.ensureCurrent();
        errors.add(error);
      }
    }

    return _PushResult(pushed: pushed, deleted: deleted, errors: errors);
  }

  Future<_PullResult> _pullRemote(
    SyncableRepository repository, {
    required DateTime? updatedAfter,
    SyncSessionToken? session,
  }) async {
    session?.ensureCurrent();
    var pulled = 0;
    var deleted = 0;
    final conflicts = <SyncConflict>[];
    final errors = <SyncError>[];
    final processedVersions = <String>{};

    final pages = repository is PagedPullSyncRepository
        ? (repository as PagedPullSyncRepository).pullPages(
            updatedAfter: updatedAfter,
          )
        : Stream<List<SyncOperation>>.fromFuture(
            repository
                .pull(updatedAfter: updatedAfter)
                .timeout(_operationTimeout),
          );
    await for (final remoteOperations in pages.timeout(_operationTimeout)) {
      session?.ensureCurrent();
      for (final remote in remoteOperations) {
        session?.ensureCurrent();
        final versionKey =
            '${remote.recordId}\u0000'
            '${remote.updatedAt.toUtc().microsecondsSinceEpoch}\u0000'
            '${remote.type.name}';
        if (!processedVersions.add(versionKey)) continue;
        try {
          final local = await repository.localOperationById(remote.recordId);
          session?.ensureCurrent();
          var operationToApply = remote;

          if (local != null &&
              !(repository is AppendOnlySyncRepository &&
                  (repository as AppendOnlySyncRepository).isAppendOnly(
                    remote,
                  ))) {
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
            session?.ensureCurrent();
            if (repository is AtomicRemoteSyncRepository) {
              await (repository as AtomicRemoteSyncRepository)
                  .applyRemoteAndMarkSynced(remote, syncedAt: _clock.now());
            } else {
              await repository.applyRemote(remote);
              session?.ensureCurrent();
              await repository.markSynced(
                remote.recordId,
                syncedAt: _clock.now(),
              );
            }
            session?.ensureCurrent();
            pulled++;
            if (remote.isDelete) deleted++;
          }
        } on SyncSessionRevokedException {
          rethrow;
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
    SyncSessionToken? session,
  }) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      session?.ensureCurrent();
      try {
        await callback().timeout(_operationTimeout);
        session?.ensureCurrent();
        return null;
      } on SyncSessionRevokedException {
        rethrow;
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
        final multiplier = 1 << attempt.clamp(0, 6);
        if (session == null) {
          await Future<void>.delayed(_retryBaseDelay * multiplier);
        } else {
          await session.cancellableDelay(_retryBaseDelay * multiplier);
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

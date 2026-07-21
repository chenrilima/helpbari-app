import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';

void main() {
  group('SyncEngine', () {
    test('does not report an empty repository set as success', () async {
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: const [],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.repositoriesProcessed, 0);
      expect(result.errors.single.operation, 'availability');
    });

    test(
      'refuses local development identity before repository access',
      () async {
        final repository = _FakeSyncableRepository();
        final engine = SyncEngine(
          stateRepository: _FakeSyncStateRepository(),
          clock: const _FixedClock(),
        );

        final result = await engine.sync(
          repositories: [repository],
          appVersion: '1.0.0',
          userId: 'dev-user',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errors.single.operation, 'identity');
        expect(repository.pullCalls, 0);
      },
    );

    test('requires an authenticated user', () async {
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: const [],
        appVersion: '1.0.0',
        userId: null,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errors.single.operation, 'availability');
    });

    test('SyncManager shares one in-flight sync without a loop', () async {
      final gate = Completer<void>();
      final repository = _FakeSyncableRepository(pullGate: gate);
      final stateRepository = _FakeSyncStateRepository();
      final sessions = SyncSessionRegistry()..activate('user-1');
      final container = ProviderContainer(
        overrides: [
          syncableRepositoriesProvider.overrideWithValue([repository]),
          syncStateRepositoryProvider.overrideWithValue(stateRepository),
          syncAppVersionProvider.overrideWithValue('test'),
          syncUserIdProvider.overrideWithValue('user-1'),
          syncSessionRegistryProvider.overrideWithValue(sessions),
          syncDataRefreshProvider.overrideWithValue((_) async {}),
        ],
      );
      addTearDown(container.dispose);

      final manager = container.read(syncManagerProvider.notifier);
      final first = manager.syncNow();
      final second = manager.syncNow();

      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(repository.pullCalls, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(repository.pullCalls, 1);
    });

    test('pushes pending local operations and updates sync state', () async {
      final repository = _FakeSyncableRepository(
        pending: [
          _operation(recordId: 'local-1', updatedAt: DateTime(2026, 7, 9, 10)),
        ],
      );
      final stateRepository = _FakeSyncStateRepository();
      final engine = SyncEngine(
        stateRepository: stateRepository,
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.pushed, 1);
      expect(repository.pushed.map((operation) => operation.recordId), [
        'local-1',
      ]);
      expect(repository.syncedIds, ['local-1']);
      expect(stateRepository.state.lastPushAt, DateTime(2026, 7, 9, 12));
      expect(stateRepository.state.userId, 'user-1');
      expect(stateRepository.state.deviceId, 'device-1');
    });

    test('pulls remote operations using lastPullAt', () async {
      final lastPullAt = DateTime(2026, 7, 8);
      final remote = _operation(
        recordId: 'remote-1',
        updatedAt: DateTime(2026, 7, 9, 9),
      );
      final repository = _FakeSyncableRepository(remote: [remote]);
      final stateRepository = _FakeSyncStateRepository(
        initialState: SyncState(lastPullAt: lastPullAt),
      );
      final engine = SyncEngine(
        stateRepository: stateRepository,
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.pulled, 1);
      expect(repository.lastPullUpdatedAfter, lastPullAt);
      expect(repository.appliedRemote.map((operation) => operation.recordId), [
        'remote-1',
      ]);
      expect(stateRepository.state.lastPullAt, DateTime(2026, 7, 9, 12));
    });

    test('reports only the domain that actually changed', () async {
      final repository = _FakeSyncableRepository(
        syncKey: 'water',
        remote: [
          _operation(recordId: 'water-1', updatedAt: DateTime(2026, 7, 9, 9)),
        ],
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.domainsChanged, {SyncDomain.water});
      expect(result.fullRefreshRequired, isFalse);
      expect(result.remoteChanges, 1);
      expect(result.userId, 'user-1');
    });

    test('retries push failures before marking operation as failed', () async {
      final operation = _operation(
        recordId: 'retry-1',
        updatedAt: DateTime(2026, 7, 9, 10),
      );
      final repository = _FakeSyncableRepository(
        pending: [operation],
        pushFailuresBeforeSuccess: 2,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
        maxRetries: 2,
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.pushed, 1);
      expect(repository.pushAttempts, 3);
      expect(repository.failedIds, isEmpty);
    });

    test('records error after retry limit is reached', () async {
      final repository = _FakeSyncableRepository(
        pending: [
          _operation(recordId: 'failed-1', updatedAt: DateTime(2026, 7, 9, 10)),
        ],
        pushFailuresBeforeSuccess: 3,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
        maxRetries: 1,
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errors, hasLength(1));
      expect(repository.failedIds, ['failed-1']);
      expect(repository.pushAttempts, 2);
    });

    test('still pushes pending records when pull fails', () async {
      final repository = _FakeSyncableRepository(
        pending: [
          _operation(recordId: 'offline-pull', updatedAt: DateTime(2026, 7, 9)),
        ],
        throwOnPull: true,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.pushed, 1);
      expect(repository.pushed.single.recordId, 'offline-pull');
      expect(result.errors.single.operation, 'pull');
    });

    test('times out a stalled pull and continues with local push', () async {
      final gate = Completer<void>();
      final repository = _FakeSyncableRepository(
        pullGate: gate,
        pending: [
          _operation(
            recordId: 'pending-after-timeout',
            updatedAt: DateTime(2026, 7, 9),
          ),
        ],
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
        operationTimeout: const Duration(milliseconds: 10),
        retryBaseDelay: Duration.zero,
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errors.single.cause, isA<TimeoutException>());
      expect(result.pushed, 1);
      expect(repository.syncedIds, ['pending-after-timeout']);
    });

    test('logout during pull discards the delayed response', () async {
      final gate = Completer<void>();
      final sessions = SyncSessionRegistry()..activate('user-1');
      final repository = _FakeSyncableRepository(
        pullGate: gate,
        remote: [
          _operation(recordId: 'old-session', updatedAt: DateTime(2026, 7, 9)),
        ],
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final sync = engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
        session: sessions.capture('user-1'),
      );
      await Future<void>.delayed(Duration.zero);
      sessions.activate(null);
      gate.complete();

      await expectLater(sync, throwsA(isA<SyncSessionRevokedException>()));
      expect(repository.appliedRemote, isEmpty);
      expect(repository.syncedIds, isEmpty);
    });

    test('account switch during push never acknowledges the old row', () async {
      final gate = Completer<void>();
      final pushStarted = Completer<void>();
      final sessions = SyncSessionRegistry()..activate('user-1');
      final repository = _FakeSyncableRepository(
        pending: [
          _operation(recordId: 'old-pending', updatedAt: DateTime(2026, 7, 9)),
        ],
        pushGate: gate,
        pushStarted: pushStarted,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final sync = engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
        session: sessions.capture('user-1'),
      );
      await pushStarted.future;
      sessions.activate('user-2');
      gate.complete();

      await expectLater(sync, throwsA(isA<SyncSessionRevokedException>()));
      expect(repository.syncedIds, isEmpty);
      expect(repository.failedIds, isEmpty);
    });

    test('session revocation interrupts retry backoff', () async {
      final sessions = SyncSessionRegistry()..activate('user-1');
      final repository = _FakeSyncableRepository(
        pending: [
          _operation(recordId: 'retry-old', updatedAt: DateTime(2026, 7, 9)),
        ],
        pushFailuresBeforeSuccess: 10,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
        maxRetries: 5,
        retryBaseDelay: const Duration(seconds: 30),
      );

      final sync = engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
        session: sessions.capture('user-1'),
      );
      while (repository.pushAttempts == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      sessions.activate(null);

      await expectLater(sync, throwsA(isA<SyncSessionRevokedException>()));
      expect(repository.pushAttempts, 1);
      expect(repository.failedIds, isEmpty);
    });

    test('resolves conflicts with latest updatedAt winning', () async {
      final local = _operation(
        recordId: 'conflict-1',
        updatedAt: DateTime(2026, 7, 9, 11),
        payload: const {'source': 'local'},
      );
      final remote = _operation(
        recordId: 'conflict-1',
        updatedAt: DateTime(2026, 7, 9, 10),
        payload: const {'source': 'remote'},
      );
      final repository = _FakeSyncableRepository(
        localById: {'conflict-1': local},
        remote: [remote],
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.conflicts, hasLength(1));
      expect(result.conflicts.single.localWon, isTrue);
      expect(repository.appliedRemote, isEmpty);
    });

    test('pulls every page and deduplicates the same remote version', () async {
      final first = _operation(
        recordId: 'page-1',
        updatedAt: DateTime(2026, 7, 9, 9),
      );
      final second = _operation(
        recordId: 'page-2',
        updatedAt: DateTime(2026, 7, 9, 9),
        type: SyncOperationType.delete,
        deletedAt: DateTime(2026, 7, 9, 9),
      );
      final repository = _FakePagedRepository(
        pages: [
          [first],
          [first, second],
        ],
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.pulled, 2);
      expect(result.deleted, 1);
      expect(repository.appliedRemote.map((value) => value.recordId), [
        'page-1',
        'page-2',
      ]);
      expect(repository.savedCursor, DateTime(2026, 7, 9, 12));
    });

    test('does not advance repository cursor after a page failure', () async {
      final repository = _FakePagedRepository(
        pages: [
          [
            _operation(
              recordId: 'page-before-error',
              updatedAt: DateTime(2026, 7, 9, 9),
            ),
          ],
        ],
        throwAfterPage: 0,
      );
      final engine = SyncEngine(
        stateRepository: _FakeSyncStateRepository(),
        clock: const _FixedClock(),
      );

      final result = await engine.sync(
        repositories: [repository],
        appVersion: '1.0.0',
        userId: 'user-1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errors.single.operation, 'pull');
      expect(repository.savedCursor, isNull);
    });

    test(
      'account switch between pages prevents later page application',
      () async {
        final nextPage = Completer<void>();
        final sessions = SyncSessionRegistry()..activate('user-1');
        final repository = _FakePagedRepository(
          pages: [
            [
              _operation(
                recordId: 'first-page',
                updatedAt: DateTime(2026, 7, 9, 9),
              ),
            ],
            [
              _operation(
                recordId: 'old-user-second-page',
                updatedAt: DateTime(2026, 7, 9, 10),
              ),
            ],
          ],
          nextPageGate: nextPage,
        );
        final engine = SyncEngine(
          stateRepository: _FakeSyncStateRepository(),
          clock: const _FixedClock(),
        );

        final sync = engine.sync(
          repositories: [repository],
          appVersion: '1.0.0',
          userId: 'user-1',
          session: sessions.capture('user-1'),
        );
        while (!repository.appliedRemote.any(
          (value) => value.recordId == 'first-page',
        )) {
          await Future<void>.delayed(Duration.zero);
        }
        sessions.activate('user-2');
        nextPage.complete();

        await expectLater(sync, throwsA(isA<SyncSessionRevokedException>()));
        expect(repository.appliedRemote.map((value) => value.recordId), [
          'first-page',
        ]);
        expect(repository.savedCursor, isNull);
      },
    );

    test(
      'applies remote conflict winner when remote updatedAt is newer',
      () async {
        final local = _operation(
          recordId: 'conflict-2',
          updatedAt: DateTime(2026, 7, 9, 10),
          payload: const {'source': 'local'},
        );
        final remote = _operation(
          recordId: 'conflict-2',
          updatedAt: DateTime(2026, 7, 9, 11),
          payload: const {'source': 'remote'},
        );
        final repository = _FakeSyncableRepository(
          localById: {'conflict-2': local},
          remote: [remote],
        );
        final engine = SyncEngine(
          stateRepository: _FakeSyncStateRepository(),
          clock: const _FixedClock(),
        );

        final result = await engine.sync(
          repositories: [repository],
          appVersion: '1.0.0',
          userId: 'user-1',
        );

        expect(result.conflicts.single.remoteWon, isTrue);
        expect(repository.appliedRemote.map((operation) => operation.payload), [
          {'source': 'remote'},
        ]);
      },
    );
  });
}

SyncOperation _operation({
  required String recordId,
  required DateTime updatedAt,
  Map<String, dynamic> payload = const {},
  SyncOperationType type = SyncOperationType.update,
  DateTime? deletedAt,
}) {
  return SyncOperation(
    repositoryKey: 'fake',
    recordId: recordId,
    type: type,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    payload: payload,
  );
}

class _FakeSyncableRepository implements SyncableRepository {
  _FakeSyncableRepository({
    List<SyncOperation> pending = const [],
    List<SyncOperation> remote = const [],
    Map<String, SyncOperation> localById = const {},
    this.pushFailuresBeforeSuccess = 0,
    this.throwOnPull = false,
    this.pullGate,
    this.pushGate,
    this.pushStarted,
    this.syncKey = 'fake',
  }) : _pending = List.of(pending),
       _remote = List.of(remote),
       _localById = Map.of(localById);

  final List<SyncOperation> _pending;
  final List<SyncOperation> _remote;
  final Map<String, SyncOperation> _localById;
  final int pushFailuresBeforeSuccess;
  final bool throwOnPull;
  final Completer<void>? pullGate;
  final Completer<void>? pushGate;
  final Completer<void>? pushStarted;
  @override
  final String syncKey;

  final pushed = <SyncOperation>[];
  final appliedRemote = <SyncOperation>[];
  final syncedIds = <String>[];
  final failedIds = <String>[];
  int pushAttempts = 0;
  DateTime? lastPullUpdatedAfter;
  int pullCalls = 0;

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    return List.of(_pending);
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    return _localById[recordId];
  }

  @override
  Future<void> push(SyncOperation operation) async {
    pushAttempts++;
    if (pushStarted != null && !pushStarted!.isCompleted) {
      pushStarted!.complete();
    }
    await pushGate?.future;
    if (pushAttempts <= pushFailuresBeforeSuccess) {
      throw StateError('temporary failure');
    }

    pushed.add(operation);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async {
    pullCalls++;
    await pullGate?.future;
    if (throwOnPull) throw StateError('pull failed');
    lastPullUpdatedAfter = updatedAfter;
    if (updatedAfter == null) return List.of(_remote);

    return _remote
        .where((operation) => operation.updatedAt.isAfter(updatedAfter))
        .toList();
  }

  @override
  Future<void> applyRemote(SyncOperation operation) async {
    appliedRemote.add(operation);
  }

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) async {
    syncedIds.add(recordId);
  }

  @override
  Future<void> markFailed(String recordId, SyncError error) async {
    failedIds.add(recordId);
  }
}

class _FakePagedRepository extends _FakeSyncableRepository
    implements PagedPullSyncRepository, RepositorySyncCursor {
  _FakePagedRepository({
    required this.pages,
    this.throwAfterPage,
    this.nextPageGate,
  });

  final List<List<SyncOperation>> pages;
  final int? throwAfterPage;
  final Completer<void>? nextPageGate;
  DateTime? savedCursor;

  @override
  Stream<List<SyncOperation>> pullPages({
    DateTime? updatedAfter,
    int pageSize = 500,
  }) async* {
    lastPullUpdatedAfter = updatedAfter;
    for (var index = 0; index < pages.length; index++) {
      if (index > 0) await nextPageGate?.future;
      yield List.of(pages[index]);
      if (throwAfterPage == index) throw StateError('page failed');
    }
  }

  @override
  Future<DateTime?> getLastPullAt() async => null;

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async {
    savedCursor = completedAt;
  }
}

class _FakeSyncStateRepository implements SyncStateRepository {
  _FakeSyncStateRepository({SyncState initialState = const SyncState()})
    : state = initialState;

  SyncState state;

  @override
  Future<SyncState> getState() async => state;

  @override
  Future<SyncState> ensureState({
    required String appVersion,
    required String? userId,
  }) async {
    state = state.copyWith(
      deviceId: state.deviceId ?? 'device-1',
      appVersion: appVersion,
      userId: userId,
    );
    return state;
  }

  @override
  Future<void> saveState(SyncState state) async {
    this.state = state;
  }
}

class _FixedClock implements ClockService {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 7, 9, 12);
}

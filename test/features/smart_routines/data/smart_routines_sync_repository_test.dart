import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/features/smart_routines/data/datasources/drift_smart_routine_datasource.dart';
import 'package:helpbari/features/smart_routines/data/datasources/smart_routine_supabase_datasource.dart';
import 'package:helpbari/features/smart_routines/data/repositories/smart_routines_sync_repository.dart';

void main() {
  const userId = '10000000-0000-4000-8000-000000000001';

  test('exposes pending operations in dependency order', () async {
    final local = _FakeLocal([
      _record('smart_routines', 'r1', userId),
      _record('routine_plans', 'p1', userId, routineId: 'r1'),
      _record('routine_schedules', 's1', userId, routineId: 'r1', planId: 'p1'),
      _record(
        'routine_occurrences',
        'o1',
        userId,
        routineId: 'r1',
        planId: 'p1',
        scheduleId: 's1',
      ),
      _record('routine_adherence_events', 'e1', userId, occurrenceId: 'o1'),
    ]);
    final repository = _repository(local, _FakeRemote(), userId);

    final operations = await repository.pendingOperations();

    expect(operations.map((operation) => operation.recordId), [
      'smart_routines:r1',
      'routine_plans:p1',
      'routine_schedules:s1',
      'routine_occurrences:o1',
      'routine_adherence_events:e1',
    ]);
  });

  test('push keeps id and uses insert-only endpoint for events', () async {
    final event = _record(
      'routine_adherence_events',
      'e1',
      userId,
      occurrenceId: 'o1',
    );
    final local = _FakeLocal([event]);
    final remote = _FakeRemote();
    final repository = _repository(local, remote, userId);
    final operation = (await repository.pendingOperations()).single;

    await repository.push(operation);
    await repository.markSynced(
      operation.recordId,
      syncedAt: DateTime.utc(2026),
    );

    expect(remote.appended, ['e1']);
    expect(remote.upserted, isEmpty);
    expect(local.statuses['routine_adherence_events:e1'], 'synced');
    expect(repository.isAppendOnly(operation), isTrue);
  });

  test('dependency pending prevents child upload', () async {
    final local = _FakeLocal([
      _record('routine_plans', 'p1', userId, routineId: 'r1'),
    ])..dependenciesReady = false;
    final remote = _FakeRemote();
    final repository = _repository(local, remote, userId);

    await expectLater(
      repository.push((await repository.pendingOperations()).single),
      throwsA(isA<StateError>()),
    );
    expect(remote.upserted, isEmpty);
  });

  test(
    'pull paginates equal timestamps and applies one ordered batch',
    () async {
      final timestamp = DateTime.utc(2026, 7, 20, 12);
      final remote = _FakeRemote()
        ..pages['smart_routines'] = [
          _remoteRow('r2', userId, timestamp),
          _remoteRow('r1', userId, timestamp),
          _remoteRow('r3', userId, timestamp),
        ]
        ..pages['routine_plans'] = [
          _remoteRow('p1', userId, timestamp, routineId: 'r1'),
        ];
      final local = _FakeLocal([]);
      final repository = _repository(local, remote, userId, pageSize: 2);

      final batch = (await repository.pull()).single;
      await repository.applyRemoteAndMarkSynced(batch, syncedAt: timestamp);

      expect(remote.pageCalls['smart_routines'], 2);
      expect(local.applyCalls, 1);
      expect(local.applied.map((record) => record.table), [
        'smart_routines',
        'smart_routines',
        'smart_routines',
        'routine_plans',
      ]);
      expect(
        local.savedCursors.keys,
        containsAll(['smart_routines', 'routine_plans']),
      );
    },
  );

  test('does not overwrite a divergent pending local payload', () async {
    final timestamp = DateTime.utc(2026, 7, 20, 12);
    final local = _FakeLocal([
      SmartRoutineLocalRecord('smart_routines', {
        ..._remoteRow('r1', userId, timestamp),
        'display_name': 'local',
        'sync_status': 'pendingUpdate',
      }),
    ]);
    final remote = _FakeRemote()
      ..pages['smart_routines'] = [
        {..._remoteRow('r1', userId, timestamp), 'display_name': 'remote'},
      ];
    final repository = _repository(local, remote, userId);

    await expectLater(repository.pull(), throwsA(isA<StateError>()));
    expect(local.applyCalls, 0);
  });

  test('real Drift applies rows and cursor in the same transaction', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final datasource = DriftSmartRoutineDatasource(
      dao: database.smartRoutineDao,
      userId: userId,
    );
    final timestamp = DateTime.utc(2026, 7, 20, 12);
    const routineId = '20000000-0000-4000-8000-000000000001';

    await datasource.applyRemoteBatch(
      [
        SmartRoutineLocalRecord('smart_routines', {
          'id': routineId,
          'user_id': userId,
          'category': 'vitamin',
          'display_name': 'B12',
          'status': 'active',
          'source': 'manual',
          'prescription_id': null,
          'prescription_item_id': null,
          'personal_notes': null,
          'icon_key': null,
          'created_at': timestamp.toIso8601String(),
          'updated_at': timestamp.toIso8601String(),
          'deleted_at': null,
        }),
      ],
      {'smart_routines': timestamp},
    );

    expect(
      await database.smartRoutineDao.getRoutine(userId, routineId),
      isNotNull,
    );
    expect(
      (await database.smartRoutineDao.getSyncCursor(
        userId,
        'smart_routines:smart_routines',
      ))?.toUtc(),
      timestamp,
    );
  });

  test(
    'real Drift rolls parents back when a child cannot be applied',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final datasource = DriftSmartRoutineDatasource(
        dao: database.smartRoutineDao,
        userId: userId,
      );
      final timestamp = DateTime.utc(2026, 7, 20, 12);
      const routineId = '20000000-0000-4000-8000-000000000002';

      await expectLater(
        datasource.applyRemoteBatch(
          [
            SmartRoutineLocalRecord('smart_routines', {
              'id': routineId,
              'user_id': userId,
              'category': 'vitamin',
              'display_name': 'B12',
              'status': 'active',
              'source': 'manual',
              'prescription_id': null,
              'prescription_item_id': null,
              'personal_notes': null,
              'icon_key': null,
              'created_at': timestamp.toIso8601String(),
              'updated_at': timestamp.toIso8601String(),
              'deleted_at': null,
            }),
            SmartRoutineLocalRecord('routine_schedules', {
              'id': '30000000-0000-4000-8000-000000000001',
              'user_id': userId,
              'routine_id': routineId,
              'plan_id': '40000000-0000-4000-8000-000000000001',
            }),
          ],
          {'smart_routines': timestamp},
        ),
        throwsStateError,
      );

      expect(
        await database.smartRoutineDao.getRoutine(userId, routineId),
        isNull,
      );
      expect(
        await database.smartRoutineDao.getSyncCursor(
          userId,
          'smart_routines:smart_routines',
        ),
        isNull,
      );
    },
  );
}

SmartRoutinesSyncRepository _repository(
  _FakeLocal local,
  _FakeRemote remote,
  String userId, {
  int pageSize = 200,
}) => SmartRoutinesSyncRepository(
  local: () async => local,
  remote: remote,
  userId: userId,
  pageSize: pageSize,
);

SmartRoutineLocalRecord _record(
  String table,
  String id,
  String userId, {
  String? routineId,
  String? planId,
  String? scheduleId,
  String? occurrenceId,
}) => SmartRoutineLocalRecord(table, {
  'id': id,
  'user_id': userId,
  'routine_id': routineId,
  'plan_id': planId,
  'schedule_id': scheduleId,
  'occurrence_id': occurrenceId,
  'created_at': DateTime.utc(2026, 7, 20),
  'updated_at': DateTime.utc(2026, 7, 20),
  'deleted_at': null,
  'sync_status': 'pendingCreate',
});

Map<String, dynamic> _remoteRow(
  String id,
  String userId,
  DateTime timestamp, {
  String? routineId,
}) => {
  'id': id,
  'user_id': userId,
  'routine_id': routineId,
  'created_at': timestamp.toIso8601String(),
  'updated_at': timestamp.toIso8601String(),
  'deleted_at': null,
};

final class _FakeLocal implements SmartRoutineLocalStore {
  _FakeLocal(this.records);
  final List<SmartRoutineLocalRecord> records;
  bool dependenciesReady = true;
  int applyCalls = 0;
  final List<SmartRoutineLocalRecord> applied = [];
  final Map<String, DateTime> savedCursors = {};
  final Map<String, String> statuses = {};

  @override
  Future<List<SmartRoutineLocalRecord>> pendingSync() async => List.of(records);
  @override
  Future<SmartRoutineLocalRecord?> byKey(String table, String id) async {
    for (final record in records) {
      if (record.table == table && record.row['id'] == id) return record;
    }
    return null;
  }

  @override
  Future<bool> dependenciesSynced(SmartRoutineLocalRecord record) async =>
      dependenciesReady;
  @override
  Future<Map<String, DateTime?>> cursors(Iterable<String> tables) async => {
    for (final table in tables) table: null,
  };
  @override
  Future<void> applyRemoteBatch(
    List<SmartRoutineLocalRecord> records,
    Map<String, DateTime> cursors,
  ) async {
    applyCalls++;
    applied.addAll(records);
    savedCursors.addAll(cursors);
  }

  @override
  Future<void> markSync(
    String table,
    String id,
    String status, {
    String? error,
  }) async {
    statuses['$table:$id'] = status;
  }
}

final class _FakeRemote implements SmartRoutineRemoteStore {
  final Map<String, List<Map<String, dynamic>>> pages = {};
  final Map<String, int> pageCalls = {};
  final List<String> appended = [];
  final List<String> upserted = [];

  @override
  Future<Map<String, dynamic>?> findById(
    String table,
    String id, {
    required String userId,
  }) async {
    for (final row in pages[table] ?? const <Map<String, dynamic>>[]) {
      if (row['id'] == id && row['user_id'] == userId) return row;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> appendEvent(
    Map<String, dynamic> input, {
    required String userId,
  }) async {
    appended.add(input['id'] as String);
    return input;
  }

  @override
  Future<Map<String, dynamic>> upsertMutable(
    String table,
    Map<String, dynamic> input, {
    required String userId,
  }) async {
    upserted.add('$table:${input['id']}');
    return input;
  }

  @override
  Future<List<Map<String, dynamic>>> pullPage({
    required String table,
    required String userId,
    required DateTime? inclusiveAfter,
    required SmartRoutineRemoteCursor? after,
    required int limit,
  }) async {
    pageCalls[table] = (pageCalls[table] ?? 0) + 1;
    final rows = List<Map<String, dynamic>>.from(pages[table] ?? const [])
      ..sort(
        (left, right) =>
            (left['id'] as String).compareTo(right['id'] as String),
      );
    final filtered = after == null
        ? rows
        : rows
              .where((row) => (row['id'] as String).compareTo(after.id) > 0)
              .toList();
    return filtered.take(limit).toList(growable: false);
  }
}

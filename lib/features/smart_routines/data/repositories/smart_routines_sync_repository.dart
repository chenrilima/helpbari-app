import 'dart:convert';

import '../../../../core/sync/sync.dart';
import '../datasources/drift_smart_routine_datasource.dart';
import '../datasources/smart_routine_supabase_datasource.dart';

final class SmartRoutinesSyncRepository
    implements
        SyncableRepository,
        AtomicRemoteSyncRepository,
        AppendOnlySyncRepository {
  const SmartRoutinesSyncRepository({
    required Future<SmartRoutineLocalStore> Function() local,
    required SmartRoutineRemoteStore remote,
    required String userId,
    this.pageSize = 200,
    SyncStatusMapper statusMapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _statusMapper = statusMapper;

  static const key = 'smart_routines';
  static const remoteBatchId = '__remote_batch__';

  final Future<SmartRoutineLocalStore> Function() _local;
  final SmartRoutineRemoteStore _remote;
  final String _userId;
  final int pageSize;
  final SyncStatusMapper _statusMapper;

  @override
  String get syncKey => key;

  @override
  bool isAppendOnly(SyncOperation operation) =>
      _tableOf(operation) == 'routine_adherence_events';

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    final records = await (await _local()).pendingSync();
    return records.map(_operation).toList(growable: false);
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    if (recordId == remoteBatchId) return null;
    final key = _decodeKey(recordId);
    final record = await (await _local()).byKey(key.table, key.id);
    return record == null ? null : _operation(record);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    _validateOperation(operation);
    final key = _decodeKey(operation.recordId);
    final local = await _local();
    final current = await local.byKey(key.table, key.id);
    if (current == null) {
      throw StateError('smart_routine_local_payload_missing');
    }
    if (!await local.dependenciesSynced(current)) {
      throw StateError('smart_routine_dependency_pending');
    }
    if (key.table != 'routine_adherence_events') {
      final remote = await _remote.findById(key.table, key.id, userId: _userId);
      if (remote != null && !_samePayload(current.row, remote)) {
        if (key.table == 'routine_occurrences' &&
            (!_sameOccurrenceIdentityPayload(current.row, remote) ||
                !_occurrenceIsUnmodified(remote))) {
          throw StateError('${key.table}_payload_conflict');
        }
        if (key.table == 'routine_plans' || key.table == 'routine_schedules') {
          // These records are immutable remotely. An existing row means a
          // previous push committed before the local sync marker was saved.
          // Never overwrite the remote clinical revision; completing this
          // operation lets the engine repair the stale local marker.
          return;
        }
        final localUpdatedAt = _date(current.row['updated_at']);
        final remoteUpdatedAt = _date(remote['updated_at']);
        if (!localUpdatedAt.isAfter(remoteUpdatedAt)) {
          throw StateError('${key.table}_payload_conflict');
        }
      }
    }
    if (key.table == 'routine_adherence_events') {
      await _remote.appendEvent(current.row, userId: _userId);
    } else {
      await _remote.upsertMutable(key.table, current.row, userId: _userId);
    }
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async {
    final local = await _local();
    final cursors = await local.cursors(
      SmartRoutineSupabaseDatasource.dependencyOrder,
    );
    final records = <SmartRoutineLocalRecord>[];
    final nextCursors = <String, DateTime>{};

    for (final table in SmartRoutineSupabaseDatasource.dependencyOrder) {
      SmartRoutineRemoteCursor? pageCursor;
      while (true) {
        final page = await _remote.pullPage(
          table: table,
          userId: _userId,
          inclusiveAfter: cursors[table],
          after: pageCursor,
          limit: pageSize,
        );
        if (page.isEmpty) break;
        for (final row in page) {
          _validateOwnership(row);
          final id = row['id'] as String;
          final existing = await local.byKey(table, id);
          if (existing != null &&
              existing.row['sync_status'] != SyncStatus.synced.name &&
              !_samePayload(existing.row, row)) {
            // Preserve the pending local command. Its push phase performs the
            // conflict policy without aborting unrelated remote rows.
            continue;
          }
          records.add(SmartRoutineLocalRecord(table, row));
        }
        final last = page.last;
        final timestamp = _cursorTimestamp(table, last);
        pageCursor = SmartRoutineRemoteCursor(timestamp, last['id'] as String);
        nextCursors[table] = timestamp;
        if (page.length < pageSize) break;
      }
    }

    if (records.isEmpty) return const [];
    return [
      SyncOperation(
        repositoryKey: key,
        recordId: remoteBatchId,
        type: SyncOperationType.update,
        updatedAt: nextCursors.values.reduce(
          (left, right) => right.isAfter(left) ? right : left,
        ),
        userId: _userId,
        payload: {
          'records': records
              .map((record) => {'table': record.table, 'row': record.row})
              .toList(growable: false),
          'cursors': nextCursors.map(
            (table, value) => MapEntry(table, value.toIso8601String()),
          ),
        },
      ),
    ];
  }

  @override
  Future<void> applyRemote(SyncOperation operation) =>
      _applyRemoteBatch(operation);

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) => _applyRemoteBatch(operation);

  Future<void> _applyRemoteBatch(SyncOperation operation) async {
    _validateOperation(operation, allowBatch: true);
    if (operation.recordId != remoteBatchId) {
      throw StateError('smart_routine_remote_batch_required');
    }
    final rawRecords = operation.payload['records'] as List? ?? const [];
    final records = rawRecords
        .map((raw) {
          final value = Map<String, dynamic>.from(raw as Map);
          return SmartRoutineLocalRecord(
            value['table'] as String,
            Map<String, dynamic>.from(value['row'] as Map),
          );
        })
        .toList(growable: false);
    final indexed = records.indexed.toList(growable: false)
      ..sort((left, right) {
        final tableOrder = SmartRoutineSupabaseDatasource.dependencyOrder
            .indexOf(left.$2.table)
            .compareTo(
              SmartRoutineSupabaseDatasource.dependencyOrder.indexOf(
                right.$2.table,
              ),
            );
        return tableOrder != 0 ? tableOrder : left.$1.compareTo(right.$1);
      });
    final orderedRecords = indexed
        .map((entry) => entry.$2)
        .toList(growable: false);
    final cursors =
        Map<String, dynamic>.from(
          operation.payload['cursors'] as Map? ?? const {},
        ).map(
          (table, value) =>
              MapEntry(table, DateTime.parse(value as String).toUtc()),
        );
    await (await _local()).applyRemoteBatch(orderedRecords, cursors);
  }

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) async {
    if (recordId == remoteBatchId) return;
    final key = _decodeKey(recordId);
    await (await _local()).markSync(key.table, key.id, SyncStatus.synced.name);
  }

  @override
  Future<void> markFailed(String recordId, SyncError error) async {
    if (recordId == remoteBatchId) return;
    final key = _decodeKey(recordId);
    await (await _local()).markSync(
      key.table,
      key.id,
      SyncStatus.failed.name,
      error: error.operation,
    );
  }

  SyncOperation _operation(SmartRoutineLocalRecord record) {
    final status = SyncStatus.fromName(record.row['sync_status'] as String?);
    return SyncOperation(
      repositoryKey: key,
      recordId: '${record.table}:${record.row['id']}',
      type: _statusMapper.operationTypeFromStatus(status),
      updatedAt: _date(record.row['updated_at'] ?? record.row['created_at']),
      deletedAt: record.row['deleted_at'] == null
          ? null
          : _date(record.row['deleted_at']),
      userId: _userId,
      payload: {'table': record.table},
    );
  }

  void _validateOperation(SyncOperation operation, {bool allowBatch = false}) {
    if (operation.repositoryKey != key || operation.userId != _userId) {
      throw StateError('smart_routine_sync_ownership_mismatch');
    }
    if (!allowBatch && operation.recordId == remoteBatchId) {
      throw StateError('smart_routine_invalid_push_batch');
    }
  }

  void _validateOwnership(Map<String, dynamic> row) {
    if (row['user_id'] != _userId) {
      throw StateError('smart_routine_remote_ownership_mismatch');
    }
  }

  String _tableOf(SyncOperation operation) =>
      operation.recordId == remoteBatchId
      ? ''
      : _decodeKey(operation.recordId).table;

  _RecordKey _decodeKey(String value) {
    final separator = value.indexOf(':');
    if (separator <= 0 || separator == value.length - 1) {
      throw FormatException('Invalid Smart Routines sync key.');
    }
    final table = value.substring(0, separator);
    if (!SmartRoutineSupabaseDatasource.dependencyOrder.contains(table)) {
      throw FormatException('Unknown Smart Routines entity type.');
    }
    return _RecordKey(table, value.substring(separator + 1));
  }

  DateTime _cursorTimestamp(String table, Map<String, dynamic> row) => _date(
    row[table == 'routine_adherence_events' ? 'created_at' : 'updated_at'],
  );

  DateTime _date(Object? value) =>
      (value is DateTime ? value : DateTime.parse(value as String)).toUtc();

  bool _samePayload(Map<String, dynamic> left, Map<String, dynamic> right) =>
      jsonEncode(_canonical(left)) == jsonEncode(_canonical(right));

  Map<String, dynamic> _canonical(Map<String, dynamic> input) {
    final value = Map<String, dynamic>.from(input)
      ..remove('sync_status')
      ..remove('previous_sync_status')
      ..remove('sync_attempts')
      ..remove('last_sync_error');
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _canonicalValue(key, value[key])};
  }

  Object? _canonicalValue(String key, Object? value) {
    if (value is DateTime) {
      return value.toUtc().millisecondsSinceEpoch ~/ 1000;
    }
    if (value is String &&
        (key.endsWith('_at') ||
            key.endsWith('_for') ||
            key.endsWith('_at_utc') ||
            key.endsWith('_for_utc'))) {
      return DateTime.parse(value).toUtc().millisecondsSinceEpoch ~/ 1000;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final keys = map.keys.toList()..sort();
      return {
        for (final childKey in keys)
          childKey: _canonicalValue(childKey, map[childKey]),
      };
    }
    if (value is List) {
      return value
          .map((item) => _canonicalValue('', item))
          .toList(growable: false);
    }
    return value;
  }

  bool _sameOccurrenceIdentityPayload(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    const fields = <String>{
      'id',
      'user_id',
      'routine_id',
      'plan_id',
      'schedule_id',
      'origin',
      'original_clinical_date',
      'original_local_hour',
      'original_local_minute',
      'original_time_zone',
      'expectation_kind',
      'sequence',
      'original_scheduled_for',
      'original_window_starts_at',
      'original_on_time_ends_at',
      'original_window_ends_at',
    };
    return fields.every(
      (field) =>
          _canonicalValue(field, left[field]) ==
          _canonicalValue(field, right[field]),
    );
  }

  bool _occurrenceIsUnmodified(Map<String, dynamic> row) =>
      row['status'] == 'expected' &&
      _canonicalValue('scheduled_for', row['scheduled_for']) ==
          _canonicalValue(
            'original_scheduled_for',
            row['original_scheduled_for'],
          ) &&
      _canonicalValue('window_starts_at', row['window_starts_at']) ==
          _canonicalValue(
            'original_window_starts_at',
            row['original_window_starts_at'],
          ) &&
      _canonicalValue('on_time_ends_at', row['on_time_ends_at']) ==
          _canonicalValue(
            'original_on_time_ends_at',
            row['original_on_time_ends_at'],
          ) &&
      _canonicalValue('window_ends_at', row['window_ends_at']) ==
          _canonicalValue(
            'original_window_ends_at',
            row['original_window_ends_at'],
          );
}

final class _RecordKey {
  const _RecordKey(this.table, this.id);
  final String table;
  final String id;
}

import '../../../../core/supabase/database/supabase_database.dart';

final class SmartRoutineRemoteRecord {
  const SmartRoutineRemoteRecord({required this.table, required this.row});
  final String table;
  final Map<String, dynamic> row;
}

final class SmartRoutineEventCursor {
  const SmartRoutineEventCursor(this.createdAtUtc, this.id);
  final DateTime createdAtUtc;
  final String id;
}

/// Thin remote boundary. Clinical validation stays in DTO/domain mappers and
/// ownership is enforced both here and by composite foreign keys/RLS.
final class SmartRoutineSupabaseDatasource {
  const SmartRoutineSupabaseDatasource(this._database);
  final SupabaseDatabase _database;

  static const dependencyOrder = <String>[
    'smart_routines',
    'routine_plans',
    'routine_schedules',
    'routine_pauses',
    'routine_occurrences',
    'routine_adherence_events',
  ];

  Future<Map<String, dynamic>> upsertMutable(
    String table,
    Map<String, dynamic> input, {
    required String userId,
  }) {
    if (table == 'routine_adherence_events') {
      throw ArgumentError.value(table, 'table', 'Events are append-only.');
    }
    final row = _remoteRow(input, userId);
    return _database.run(
      operation: 'upsert',
      table: table,
      request: (query) async =>
          Map<String, dynamic>.from(await query.upsert(row).select().single()),
    );
  }

  Future<Map<String, dynamic>> appendEvent(
    Map<String, dynamic> input, {
    required String userId,
  }) async {
    final row = _remoteRow(input, userId);
    final id = row['id'] as String;
    final existing = await _database.run(
      operation: 'select',
      table: 'routine_adherence_events',
      request: (query) async => (await query
          .select()
          .eq('user_id', userId)
          .eq('id', id)
          .maybeSingle()),
    );
    if (existing != null) {
      final current = Map<String, dynamic>.from(existing);
      if (!_sameClinicalEvent(current, row)) {
        throw StateError('routine_adherence_event_payload_conflict');
      }
      return current;
    }
    return _database.run(
      operation: 'insert',
      table: 'routine_adherence_events',
      request: (query) async =>
          Map<String, dynamic>.from(await query.insert(row).select().single()),
    );
  }

  Future<List<SmartRoutineRemoteRecord>> pullMutable({
    required String userId,
    DateTime? updatedAfter,
  }) async {
    final records = <SmartRoutineRemoteRecord>[];
    for (final table in dependencyOrder.take(5)) {
      final rows = await _database.run(
        operation: 'select',
        table: table,
        request: (query) async {
          var request = query.select().eq('user_id', userId);
          if (updatedAfter != null) {
            request = request.gte(
              'updated_at',
              updatedAfter.toUtc().toIso8601String(),
            );
          }
          return (await request.order('updated_at').order('id'))
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false);
        },
      );
      records.addAll(
        rows.map((row) => SmartRoutineRemoteRecord(table: table, row: row)),
      );
    }
    return records;
  }

  Future<List<Map<String, dynamic>>> pullEvents({
    required String userId,
    SmartRoutineEventCursor? after,
  }) => _database.run(
    operation: 'select',
    table: 'routine_adherence_events',
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (after != null) {
        final instant = after.createdAtUtc.toIso8601String();
        request = request.or(
          'created_at.gt.$instant,and(created_at.eq.$instant,id.gt.${after.id})',
        );
      }
      return (await request.order('created_at').order('id'))
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    },
  );

  Map<String, dynamic> _remoteRow(Map<String, dynamic> input, String userId) {
    if (input['user_id'] != userId) {
      throw StateError('smart_routine_user_mismatch');
    }
    return Map<String, dynamic>.from(input)
      ..remove('sync_status')
      ..remove('previous_sync_status')
      ..remove('sync_attempts')
      ..remove('last_sync_error')
      ..updateAll(
        (key, value) =>
            value is DateTime ? value.toUtc().toIso8601String() : value,
      );
  }

  bool _sameClinicalEvent(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    const ignored = {'created_at'};
    final leftClinical = Map<String, dynamic>.from(left)
      ..removeWhere((key, _) => ignored.contains(key));
    final rightClinical = Map<String, dynamic>.from(right)
      ..removeWhere((key, _) => ignored.contains(key));
    return leftClinical.toString() == rightClinical.toString();
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../interceptors/supabase_request_interceptor.dart';

class SupabaseDatabase {
  const SupabaseDatabase({
    required SupabaseClient client,
    required SupabaseInterceptorRunner interceptorRunner,
  }) : _client = client,
       _interceptorRunner = interceptorRunner;

  final SupabaseClient _client;
  final SupabaseInterceptorRunner _interceptorRunner;

  Future<DateTime> serverNow() => _interceptorRunner.run(
    context: const SupabaseRequestContext(
      operation: 'serverNow',
      table: 'sync_server_now',
      metadata: {'requiresAuth': true},
    ),
    request: () async =>
        DateTime.parse(await _client.rpc<String>('sync_server_now')).toUtc(),
  );

  Future<Map<String, dynamic>> versionedUpsert({
    required String table,
    required String userId,
    required String recordId,
    required Map<String, dynamic> row,
    required int? baseRevision,
  }) => run(
    operation: 'versionedUpsert',
    table: table,
    request: (query) async {
      final payload = Map<String, dynamic>.from(row)..remove('server_revision');
      if (baseRevision != null) {
        final updated = await query
            .update(payload)
            .eq('user_id', userId)
            .eq('id', recordId)
            .eq('server_revision', baseRevision)
            .select()
            .maybeSingle();
        if (updated != null) return Map<String, dynamic>.from(updated);
      }

      final existing = await query
          .select()
          .eq('user_id', userId)
          .eq('id', recordId)
          .maybeSingle();
      if (existing != null) {
        throw SupabaseRevisionConflictException(
          Map<String, dynamic>.from(existing),
        );
      }

      try {
        return Map<String, dynamic>.from(
          await query.insert(payload).select().single(),
        );
      } on PostgrestException catch (error) {
        if (error.code != '23505') rethrow;
        final raced = await query
            .select()
            .eq('user_id', userId)
            .eq('id', recordId)
            .maybeSingle();
        if (raced == null) rethrow;
        throw SupabaseRevisionConflictException(
          Map<String, dynamic>.from(raced),
        );
      }
    },
  );

  SupabaseQueryBuilder from(String table) {
    return _client.from(table);
  }

  Future<T> run<T>({
    required String operation,
    required String table,
    required Future<T> Function(SupabaseQueryBuilder query) request,
    bool requiresAuth = true,
  }) {
    return _interceptorRunner.run(
      context: SupabaseRequestContext(
        operation: operation,
        table: table,
        metadata: {'requiresAuth': requiresAuth},
      ),
      request: () => request(_client.from(table)),
    );
  }

  Stream<List<Map<String, dynamic>>> pullUpdatedPages({
    required String table,
    required String userId,
    DateTime? updatedAfter,
    int pageSize = 500,
  }) async* {
    DateTime? cursorAt = updatedAfter?.toUtc();
    String? cursorId;
    while (true) {
      final rows = await run<List<Map<String, dynamic>>>(
        operation: 'selectPage',
        table: table,
        request: (query) async {
          var request = query.select().eq('user_id', userId);
          if (cursorAt != null && cursorId == null) {
            request = request.gt('updated_at', cursorAt.toIso8601String());
          } else if (cursorAt != null && cursorId != null) {
            final instant = cursorAt.toIso8601String();
            request = request.or(
              'updated_at.gt.$instant,'
              'and(updated_at.eq.$instant,id.gt.$cursorId)',
            );
          }
          final response = await request
              .order('updated_at')
              .order('id')
              .limit(pageSize);
          return response
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false);
        },
      );
      if (rows.isEmpty) return;
      yield rows;
      final last = rows.last;
      cursorAt = DateTime.parse(last['updated_at'] as String).toUtc();
      cursorId = last['id'] as String;
      if (rows.length < pageSize) return;
    }
  }
}

final class SupabaseRevisionConflictException implements Exception {
  const SupabaseRevisionConflictException(this.remoteRow);

  final Map<String, dynamic> remoteRow;

  @override
  String toString() => 'Remote record revision advanced.';
}

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

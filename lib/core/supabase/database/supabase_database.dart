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
}

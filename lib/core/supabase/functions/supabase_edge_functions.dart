import 'package:supabase_flutter/supabase_flutter.dart';

import '../interceptors/supabase_request_interceptor.dart';

class SupabaseEdgeFunctions {
  const SupabaseEdgeFunctions({
    required SupabaseClient client,
    required SupabaseInterceptorRunner interceptorRunner,
  }) : _client = client,
       _interceptorRunner = interceptorRunner;

  final SupabaseClient _client;
  final SupabaseInterceptorRunner _interceptorRunner;

  Future<FunctionResponse> invoke(
    String functionName, {
    Object? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _interceptorRunner.run(
      context: SupabaseRequestContext(
        operation: 'functions.invoke',
        functionName: functionName,
        metadata: {'requiresAuth': requiresAuth},
      ),
      request: () =>
          _client.functions.invoke(functionName, body: body, headers: headers),
    );
  }
}

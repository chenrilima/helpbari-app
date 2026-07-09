import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRequestContext {
  const SupabaseRequestContext({
    required this.operation,
    this.table,
    this.bucket,
    this.functionName,
    this.metadata = const {},
  });

  final String operation;
  final String? table;
  final String? bucket;
  final String? functionName;
  final Map<String, Object?> metadata;
}

abstract interface class SupabaseRequestInterceptor {
  Future<void> onRequest(SupabaseRequestContext context);

  Future<void> onResponse(SupabaseRequestContext context, Object? response);

  Future<void> onError(
    SupabaseRequestContext context,
    Object error,
    StackTrace stackTrace,
  );
}

class SupabaseInterceptorRunner {
  const SupabaseInterceptorRunner(this._interceptors);

  final List<SupabaseRequestInterceptor> _interceptors;

  Future<T> run<T>({
    required SupabaseRequestContext context,
    required Future<T> Function() request,
  }) async {
    for (final interceptor in _interceptors) {
      await interceptor.onRequest(context);
    }

    try {
      final response = await request();

      for (final interceptor in _interceptors) {
        await interceptor.onResponse(context, response);
      }

      return response;
    } catch (error, stackTrace) {
      for (final interceptor in _interceptors) {
        await interceptor.onError(context, error, stackTrace);
      }

      rethrow;
    }
  }
}

extension SupabaseUserX on SupabaseClient {
  String? get currentUserId => auth.currentUser?.id;
}

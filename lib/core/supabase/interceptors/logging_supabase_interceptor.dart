import '../../logger/app_logger.dart';
import 'supabase_request_interceptor.dart';

class LoggingSupabaseInterceptor implements SupabaseRequestInterceptor {
  const LoggingSupabaseInterceptor();

  @override
  Future<void> onRequest(SupabaseRequestContext context) async {
    AppLogger.debug('Supabase request: ${context.operation}');
  }

  @override
  Future<void> onResponse(
    SupabaseRequestContext context,
    Object? response,
  ) async {
    AppLogger.debug('Supabase response: ${context.operation}');
  }

  @override
  Future<void> onError(
    SupabaseRequestContext context,
    Object error,
    StackTrace stackTrace,
  ) async {
    AppLogger.error(
      'Supabase error: ${context.operation}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

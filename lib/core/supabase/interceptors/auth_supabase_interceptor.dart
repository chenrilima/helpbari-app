import '../../failures/failures.dart';
import 'supabase_request_interceptor.dart';

class AuthSupabaseInterceptor implements SupabaseRequestInterceptor {
  const AuthSupabaseInterceptor({required this.currentUserId});

  final String? Function() currentUserId;

  @override
  Future<void> onRequest(SupabaseRequestContext context) async {
    final requiresAuth = context.metadata['requiresAuth'] == true;

    if (requiresAuth && currentUserId() == null) {
      throw const AuthFailure(
        message: 'Sessão expirada. Entre novamente.',
        code: 'auth_required',
      ).toException();
    }
  }

  @override
  Future<void> onResponse(
    SupabaseRequestContext context,
    Object? response,
  ) async {}

  @override
  Future<void> onError(
    SupabaseRequestContext context,
    Object error,
    StackTrace stackTrace,
  ) async {}
}

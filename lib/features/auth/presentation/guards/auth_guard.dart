import '../../../../app/router/app_routes.dart';
import '../states/auth_state.dart';

class AuthGuard {
  const AuthGuard._();

  static const publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.signUp,
  };

  static String? redirect({
    required String location,
    required AuthState authState,
  }) {
    final isPublicRoute = publicRoutes.contains(location);

    return switch (authState) {
      AuthInitial() ||
      AuthLoading() => location == AppRoutes.splash ? null : AppRoutes.splash,
      AuthAuthenticated() => isPublicRoute ? AppRoutes.home : null,
      AuthUnauthenticated() ||
      AuthFailure() => isPublicRoute ? null : AppRoutes.login,
    };
  }
}

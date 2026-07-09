import '../../../../app/router/app_routes.dart';
import '../states/auth_state.dart';

class AuthGuard {
  const AuthGuard._();

  static const publicRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.signUp,
    AppRoutes.resetPassword,
  };

  static String? redirect({
    required String location,
    required AuthState authState,
  }) {
    final isPublicRoute = publicRoutes.contains(location);

    return switch (authState) {
      AuthInitial() ||
      AuthLoading() => location == AppRoutes.splash ? null : AppRoutes.splash,
      AuthPasswordRecoveryReady() =>
        location == AppRoutes.resetPassword ? null : AppRoutes.resetPassword,
      AuthAuthenticated() => isPublicRoute ? AppRoutes.home : null,
      AuthPasswordUpdated() => isPublicRoute ? AppRoutes.home : null,
      AuthUnauthenticated() ||
      AuthPasswordRecoverySent() ||
      AuthFailure() => isPublicRoute ? null : AppRoutes.login,
    };
  }
}

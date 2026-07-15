import '../../../../app/router/app_routes.dart';
import '../states/auth_state.dart';

class AuthGuard {
  const AuthGuard._();

  static const publicRoutes = {
    AppRoutes.splash,
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
      AuthAuthenticated() =>
        location == AppRoutes.onboarding
            ? null
            : isPublicRoute
            ? AppRoutes.home
            : null,
      AuthPasswordUpdated() =>
        location == AppRoutes.onboarding
            ? null
            : isPublicRoute
            ? AppRoutes.home
            : null,
      AuthUnauthenticated() ||
      AuthEmailConfirmationRequired() ||
      AuthPasswordRecoverySent() ||
      AuthFailure() =>
        location == AppRoutes.login ||
                location == AppRoutes.signUp ||
                location == AppRoutes.resetPassword
            ? null
            : AppRoutes.login,
    };
  }
}

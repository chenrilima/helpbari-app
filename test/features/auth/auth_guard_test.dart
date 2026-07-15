import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/features/auth/domain/entities/auth_user.dart';
import 'package:helpbari/features/auth/presentation/guards/auth_guard.dart';
import 'package:helpbari/features/auth/presentation/states/auth_state.dart';

void main() {
  const user = AuthUser(id: 'user-a', email: 'ana@example.com');

  test('loading session stays on splash without a redirect loop', () {
    expect(
      AuthGuard.redirect(
        location: AppRoutes.home,
        authState: const AuthLoading(),
      ),
      AppRoutes.splash,
    );
    expect(
      AuthGuard.redirect(
        location: AppRoutes.splash,
        authState: const AuthLoading(),
      ),
      isNull,
    );
  });

  test('unauthenticated user leaves splash for login', () {
    expect(
      AuthGuard.redirect(
        location: AppRoutes.splash,
        authState: const AuthUnauthenticated(),
      ),
      AppRoutes.login,
    );
    expect(
      AuthGuard.redirect(
        location: AppRoutes.login,
        authState: const AuthUnauthenticated(),
      ),
      isNull,
    );
  });

  test('onboarding is not a public route', () {
    expect(
      AuthGuard.redirect(
        location: AppRoutes.onboarding,
        authState: const AuthUnauthenticated(),
      ),
      AppRoutes.login,
    );
  });

  test('email confirmation does not grant access to Home', () {
    expect(
      AuthGuard.redirect(
        location: AppRoutes.home,
        authState: const AuthEmailConfirmationRequired(),
      ),
      AppRoutes.login,
    );
  });

  test('authenticated public-route access proceeds toward the app', () {
    expect(
      AuthGuard.redirect(
        location: AppRoutes.login,
        authState: const AuthAuthenticated(user),
      ),
      AppRoutes.home,
    );
  });
}

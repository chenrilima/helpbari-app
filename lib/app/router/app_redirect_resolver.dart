import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/guards/auth_guard.dart';
import '../../features/auth/presentation/states/auth_state.dart';
import '../../features/onboarding/presentation/states/onboarding_state.dart';
import '../../features/profile/presentation/guards/profile_guard.dart';
import '../../features/profile/presentation/states/profile_state.dart';
import 'onboarding_guard.dart';

abstract final class AppRedirectResolver {
  static String? resolve({
    required String location,
    required AuthUser? session,
    required AuthState authState,
    required OnboardingState onboardingState,
    required ProfileState profileState,
  }) {
    final hasAuthenticatedState =
        authState is AuthAuthenticated || authState is AuthPasswordUpdated;
    if (hasAuthenticatedState &&
        onboardingState.entryStatus == AppEntryStatus.loading) {
      return null;
    }

    final authRedirect = AuthGuard.redirect(
      location: location,
      authState: authState,
    );
    if (authRedirect != null) return authRedirect;

    // While authentication is being restored, the current splash route must
    // remain stable until AuthState reaches a definitive value.
    if (authState is AuthInitial || authState is AuthLoading) return null;

    final onboardingRedirect = OnboardingGuard.redirect(
      location: location,
      session: session,
      state: onboardingState,
    );
    if (onboardingRedirect != null) return onboardingRedirect;

    if (session == null) return null;
    return ProfileGuard.redirect(location: location, state: profileState);
  }
}

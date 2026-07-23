import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/states/auth_state.dart';
import '../../features/onboarding/presentation/states/onboarding_state.dart';
import '../../features/profile/presentation/states/profile_state.dart';
import 'app_routes.dart';

enum AppEntryPhase {
  initializing,
  unauthenticated,
  authenticatedResolvingAccount,
  onboardingRequired,
  ready,
  sessionExpired,
  fatalRecovery,
}

abstract final class AppRedirectResolver {
  static String? resolve({
    required String location,
    required AuthUser? session,
    required AuthState authState,
    required OnboardingState onboardingState,
    required ProfileState profileState,
  }) {
    if (authState is AuthPasswordRecoveryReady) {
      return location == AppRoutes.resetPassword
          ? null
          : AppRoutes.resetPassword;
    }
    final phase = phaseFor(
      session: session,
      authState: authState,
      onboardingState: onboardingState,
    );
    return switch (phase) {
      AppEntryPhase.initializing ||
      AppEntryPhase.authenticatedResolvingAccount =>
        location == AppRoutes.splash ? null : AppRoutes.splash,
      AppEntryPhase.unauthenticated || AppEntryPhase.sessionExpired =>
        location == AppRoutes.login ||
                location == AppRoutes.signUp ||
                location == AppRoutes.resetPassword
            ? null
            : AppRoutes.login,
      AppEntryPhase.onboardingRequired || AppEntryPhase.fatalRecovery =>
        location == AppRoutes.onboarding ? null : AppRoutes.onboarding,
      AppEntryPhase.ready =>
        isPublic(location) || location == AppRoutes.onboarding
            ? AppRoutes.home
            : null,
    };
  }

  static AppEntryPhase phaseFor({
    required AuthUser? session,
    required AuthState authState,
    required OnboardingState onboardingState,
  }) {
    if (authState is AuthInitial || authState is AuthLoading) {
      return AppEntryPhase.initializing;
    }
    if (session == null) {
      return authState is AuthFailure
          ? AppEntryPhase.sessionExpired
          : AppEntryPhase.unauthenticated;
    }
    return switch (onboardingState.entryStatus) {
      AppEntryStatus.loading => AppEntryPhase.authenticatedResolvingAccount,
      AppEntryStatus.authenticatedOnboardingPending ||
      AppEntryStatus.authenticatedLegalAcceptancePending =>
        AppEntryPhase.onboardingRequired,
      AppEntryStatus.authenticatedReady => AppEntryPhase.ready,
      AppEntryStatus.failure => AppEntryPhase.fatalRecovery,
      AppEntryStatus.unauthenticated =>
        AppEntryPhase.authenticatedResolvingAccount,
    };
  }

  static bool isPublic(String location) => const {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.signUp,
    AppRoutes.resetPassword,
  }.contains(location);
}

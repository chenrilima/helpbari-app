import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/onboarding/presentation/states/onboarding_state.dart';
import 'app_routes.dart';

abstract final class OnboardingGuard {
  static String? redirect({
    required String location,
    required AuthUser? session,
    required OnboardingState state,
  }) {
    final isOnboardingRoute = location == AppRoutes.onboarding;
    if (session == null) {
      return isOnboardingRoute ? AppRoutes.login : null;
    }

    return switch (state.entryStatus) {
      AppEntryStatus.loading =>
        location == AppRoutes.splash ? null : AppRoutes.splash,
      AppEntryStatus.authenticatedOnboardingPending ||
      AppEntryStatus.authenticatedLegalAcceptancePending ||
      AppEntryStatus.failure => isOnboardingRoute ? null : AppRoutes.onboarding,
      AppEntryStatus.authenticatedReady =>
        isOnboardingRoute || location == AppRoutes.splash
            ? AppRoutes.home
            : null,
      AppEntryStatus.unauthenticated =>
        location == AppRoutes.splash ? null : AppRoutes.splash,
    };
  }
}

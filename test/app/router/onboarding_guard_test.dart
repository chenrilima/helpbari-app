import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/app/router/onboarding_guard.dart';
import 'package:helpbari/features/auth/domain/entities/auth_user.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/onboarding/presentation/states/onboarding_state.dart';

void main() {
  const user = AuthUser(id: 'user-a', email: 'ana@example.com');

  test('unauthenticated user cannot enter onboarding before login', () {
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.onboarding,
        session: null,
        state: _state(isAuthenticated: false, introductionCompleted: false),
      ),
      AppRoutes.login,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.login,
        session: null,
        state: _state(isAuthenticated: false, introductionCompleted: false),
      ),
      isNull,
    );
  });

  test('authenticated loading state remains on splash without loop', () {
    final state = _state(isResolvingSession: true);
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: state,
      ),
      AppRoutes.splash,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.splash,
        session: user,
        state: state,
      ),
      isNull,
    );
  });

  test('new authenticated session waits for onboarding state on splash', () {
    final staleState = _state(isAuthenticated: false);
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: staleState,
      ),
      AppRoutes.splash,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.splash,
        session: user,
        state: staleState,
      ),
      isNull,
    );
  });

  test('authenticated user with incomplete remote data stays onboarding', () {
    final state = _state();
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: state,
      ),
      AppRoutes.onboarding,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.onboarding,
        session: user,
        state: state,
      ),
      isNull,
    );
  });

  test('stale legal consent blocks Home', () {
    final state = _state(hasProfile: true);
    expect(
      state.entryStatus,
      AppEntryStatus.authenticatedLegalAcceptancePending,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: state,
      ),
      AppRoutes.onboarding,
    );
  });

  test('restored profile and current consent route directly to Home', () {
    final state = _state(
      userCompleted: true,
      hasProfile: true,
      hasCurrentLegalConsent: true,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.onboarding,
        session: user,
        state: state,
      ),
      AppRoutes.home,
    );
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: state,
      ),
      isNull,
    );
  });

  test('resolution failure is safe and never grants Home', () {
    final state = _state(resolutionFailed: true);
    expect(
      OnboardingGuard.redirect(
        location: AppRoutes.home,
        session: user,
        state: state,
      ),
      AppRoutes.onboarding,
    );
  });
}

OnboardingState _state({
  bool introductionCompleted = true,
  bool isAuthenticated = true,
  bool userCompleted = false,
  bool isResolvingSession = false,
  bool hasProfile = false,
  bool hasCurrentLegalConsent = false,
  bool resolutionFailed = false,
}) => OnboardingState(
  introductionCompleted: introductionCompleted,
  userCompleted: userCompleted,
  isAuthenticated: isAuthenticated,
  draft: const OnboardingProfileDraft(),
  isResolvingSession: isResolvingSession,
  hasProfile: hasProfile,
  hasCurrentLegalConsent: hasCurrentLegalConsent,
  resolutionFailed: resolutionFailed,
);

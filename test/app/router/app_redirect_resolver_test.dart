import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/app_redirect_resolver.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/features/auth/domain/entities/auth_user.dart';
import 'package:helpbari/features/auth/presentation/states/auth_state.dart';
import 'package:helpbari/features/onboarding/presentation/states/onboarding_state.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/profile/presentation/states/profile_state.dart';

void main() {
  const user = AuthUser(id: 'user-a', email: 'ana@example.com');

  test('keeps splash stable while auth restoration is loading', () {
    const onboarding = OnboardingState(
      introductionCompleted: true,
      userCompleted: true,
      isAuthenticated: true,
      draft: OnboardingProfileDraft(),
      hasProfile: true,
      hasCurrentLegalConsent: true,
    );

    final fromHome = AppRedirectResolver.resolve(
      location: AppRoutes.home,
      session: user,
      authState: const AuthLoading(),
      onboardingState: onboarding,
      profileState: const ProfileState(),
    );
    final fromSplash = AppRedirectResolver.resolve(
      location: AppRoutes.splash,
      session: user,
      authState: const AuthLoading(),
      onboardingState: onboarding,
      profileState: const ProfileState(),
    );

    expect(fromHome, AppRoutes.splash);
    expect(fromSplash, isNull);
  });

  test(
    'keeps current route stable while authenticated onboarding restores',
    () {
      const onboarding = OnboardingState(
        introductionCompleted: true,
        userCompleted: true,
        isAuthenticated: true,
        draft: OnboardingProfileDraft(),
        isResolvingSession: true,
        hasProfile: true,
        hasCurrentLegalConsent: true,
      );
      const authState = AuthAuthenticated(user);

      final fromHome = AppRedirectResolver.resolve(
        location: AppRoutes.home,
        session: user,
        authState: authState,
        onboardingState: onboarding,
        profileState: const ProfileState(),
      );
      final fromSplash = AppRedirectResolver.resolve(
        location: AppRoutes.splash,
        session: user,
        authState: authState,
        onboardingState: onboarding,
        profileState: const ProfileState(),
      );

      expect(onboarding.entryStatus, AppEntryStatus.loading);
      expect(fromHome, AppRoutes.splash);
      expect(fromSplash, isNull);
    },
  );
}

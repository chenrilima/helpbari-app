import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/features/meals/presentation/pages/meals_page.dart';
import 'package:helpbari/features/meals/domain/entities/entities.dart'
    show Meal;
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/register_appointment_page.dart';
import '../../features/appointments/domain/entities/entities.dart'
    show Appointment;
import '../../features/baria/presentation/pages/baria_page.dart';
import '../../features/exams/presentation/pages/exams_page.dart';
import '../../features/exams/presentation/pages/register_exam_page.dart';
import '../../features/exams/presentation/pages/exam_details_page.dart';
import '../../features/exams/domain/entities/entities.dart' show Exam;
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/meals/presentation/pages/register_meal_page.dart';
import '../../features/medical_reports/presentation/pages/medical_reports_page.dart';
import '../../features/medications/presentation/pages/medications_page.dart';
import '../../features/medications/presentation/pages/register_medication_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/profile/presentation/pages/complete_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/guards/profile_guard.dart';
import '../../features/profile/presentation/providers/profile_view_model_provider.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/showcase/presentation/pages/showcase_page.dart';
import '../../core/supabase/session/session_manager_provider.dart';
import '../../features/auth/presentation/guards/auth_guard.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/vitamins/presentation/pages/register_vitamin_page.dart';
import '../../features/vitamins/presentation/pages/vitamins_page.dart';
import '../../features/water/presentation/pages/register_water_page.dart';
import '../../features/water/presentation/pages/water_page.dart';
import '../../features/water/domain/entities/entities.dart';
import '../../features/weight/presentation/pages/register_weight_page.dart';
import '../../features/weight/presentation/pages/weight_page.dart';
import '../../features/weight/domain/entities/entities.dart' show WeightRecord;
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _GoRouterRefreshStream(
    ref.watch(sessionManagerProvider).authStateChanges,
  );

  ref.listen(onboardingViewModelProvider, (previous, next) {
    refreshListenable.notify();
  });

  ref.listen(authViewModelProvider, (previous, next) {
    refreshListenable.notify();
    if (ref.read(authSessionProvider) != null) {
      unawaited(ref.read(profileViewModelProvider.notifier).loadProfile());
    }
  });
  ref.listen(
    profileViewModelProvider,
    (previous, next) => refreshListenable.notify(),
  );
  if (ref.read(authSessionProvider) != null) {
    Future.microtask(
      () => ref.read(profileViewModelProvider.notifier).loadProfile(),
    );
  }

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final location = state.uri.path;
      final onboardingState = ref.read(onboardingViewModelProvider);
      final isOnboardingRoute = location == AppRoutes.onboarding;

      if (!onboardingState.introductionCompleted) {
        return isOnboardingRoute ? null : AppRoutes.onboarding;
      }

      final session = ref.read(authSessionProvider);
      if (session == null && isOnboardingRoute) return AppRoutes.login;
      if (session != null && !onboardingState.userCompleted) {
        return isOnboardingRoute ? null : AppRoutes.onboarding;
      }
      if (session != null && isOnboardingRoute) return AppRoutes.home;

      final authRedirect = AuthGuard.redirect(
        location: location,
        authState: ref.read(authViewModelProvider),
      );
      if (authRedirect != null) return authRedirect;
      if (session != null) {
        return ProfileGuard.redirect(
          location: location,
          state: ref.read(profileViewModelProvider),
        );
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.showcase,
        builder: (context, state) => const ShowcasePage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(path: AppRoutes.weight, builder: (_, _) => const WeightPage()),

      GoRoute(
        path: AppRoutes.registerWeight,
        builder: (_, state) => RegisterWeightPage(
          record: state.extra is WeightRecord
              ? state.extra! as WeightRecord
              : null,
        ),
      ),
      GoRoute(path: AppRoutes.water, builder: (_, _) => const WaterPage()),
      GoRoute(
        path: AppRoutes.registerWater,
        builder: (_, state) => RegisterWaterPage(
          record: state.extra is WaterRecord
              ? state.extra! as WaterRecord
              : null,
        ),
      ),
      GoRoute(path: AppRoutes.baria, builder: (_, _) => const BariaPage()),
      GoRoute(
        path: AppRoutes.vitamins,
        builder: (context, state) => const VitaminsPage(),
      ),
      GoRoute(
        path: AppRoutes.registerVitamin,
        builder: (context, state) => const RegisterVitaminPage(),
      ),
      GoRoute(
        path: AppRoutes.registerAppointment,
        builder: (context, state) => RegisterAppointmentPage(
          appointment: state.extra is Appointment
              ? state.extra! as Appointment
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.appointments,
        builder: (context, state) => const AppointmentsPage(),
      ),
      GoRoute(
        path: AppRoutes.exams,
        builder: (context, state) => const ExamsPage(),
      ),
      GoRoute(
        path: AppRoutes.registerExam,
        builder: (context, state) => RegisterExamPage(
          exam: state.extra is Exam ? state.extra! as Exam : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.examDetails,
        builder: (context, state) =>
            ExamDetailsPage(exam: state.extra! as Exam),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressPage(),
      ),
      GoRoute(
        path: AppRoutes.medications,
        builder: (context, state) => const MedicationsPage(),
      ),
      GoRoute(
        path: AppRoutes.registerMedication,
        builder: (context, state) => const RegisterMedicationPage(),
      ),
      GoRoute(
        path: AppRoutes.meals,
        builder: (context, state) => const MealsPage(),
      ),
      GoRoute(
        path: AppRoutes.registerMeal,
        builder: (context, state) => RegisterMealPage(
          meal: state.extra is Meal ? state.extra! as Meal : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.medicalReports,
        builder: (context, state) => const MedicalReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
  );

  ref.onDispose(() {
    refreshListenable.dispose();
    router.dispose();
  });

  return router;
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<Object?> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  void notify() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

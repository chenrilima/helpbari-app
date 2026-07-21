import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show GlobalKey, NavigatorState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/features/meals/presentation/pages/meals_page.dart';
import 'package:helpbari/features/meals/domain/entities/entities.dart'
    show Meal;
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/register_appointment_page.dart';
import '../../features/appointments/domain/entities/entities.dart'
    show Appointment;
import '../../features/academy/presentation/pages/academy_article_page.dart';
import '../../features/academy/presentation/pages/academy_faq_page.dart';
import '../../features/academy/presentation/pages/academy_glossary_page.dart';
import '../../features/academy/presentation/pages/academy_history_page.dart';
import '../../features/academy/presentation/pages/academy_page.dart';
import '../../features/baria/presentation/pages/baria_page.dart';
import '../../features/bioimpedance/presentation/pages/bioimpedance_details_page.dart';
import '../../features/bioimpedance/presentation/pages/bioimpedance_page.dart';
import '../../features/bioimpedance/presentation/pages/register_bioimpedance_page.dart';
import '../../features/medical_exams/domain/entities/entities.dart'
    show MedicalExam;
import '../../features/medical_exams/presentation/pages/medical_exam_details_page.dart';
import '../../features/medical_exams/presentation/pages/medical_exams_page.dart';
import '../../features/medical_exams/presentation/pages/register_medical_exam_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/more/presentation/pages/more_page.dart';
import '../../features/treatment/presentation/pages/treatment_page.dart';
import '../../features/meals/presentation/pages/register_meal_page.dart';
import '../../features/medical_reports/presentation/pages/medical_reports_page.dart';
import '../../features/medical_prescriptions/domain/entities/entities.dart';
import '../../features/medical_prescriptions/presentation/pages/add_prescription_to_routine_page.dart';
import '../../features/medical_prescriptions/presentation/pages/medical_prescription_details_page.dart';
import '../../features/medical_prescriptions/presentation/pages/medical_prescriptions_page.dart';
import '../../features/medical_prescriptions/presentation/pages/medical_prescription_route_page.dart';
import '../../features/medical_prescriptions/presentation/pages/register_medical_prescription_page.dart';
import '../../features/document_intelligence/presentation/pages/document_center_page.dart';
import '../../features/medications/presentation/pages/register_medication_page.dart';
import '../../features/medications/domain/entities/medication.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/profile/presentation/pages/complete_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/providers/profile_view_model_provider.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/privacy/presentation/pages/privacy_page.dart';
import '../../features/showcase/presentation/pages/showcase_page.dart';
import '../../core/supabase/session/session_manager_provider.dart';
import '../../core/services/service_providers.dart';
import '../../core/services/notifications/notifications.dart';
import '../../features/smart_routines/application/notification_platform.dart';
import '../../features/smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/vitamins/presentation/pages/register_vitamin_page.dart';
import '../../features/vitamins/domain/entities/vitamin.dart';
import '../../features/water/presentation/pages/register_water_page.dart';
import '../../features/water/presentation/pages/water_page.dart';
import '../../features/water/domain/entities/entities.dart';
import '../../features/weight/presentation/pages/register_weight_page.dart';
import '../../features/weight/presentation/pages/weight_page.dart';
import '../../features/weight/domain/entities/entities.dart' show WeightRecord;
import '../../features/bioimpedance/domain/entities/entities.dart'
    show BioimpedanceRecord;
import 'app_routes.dart';
import 'app_redirect_resolver.dart';
import 'notification_navigation.dart';
import '../shell/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  String? pendingDestination;
  String? pendingUserId;
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
    navigatorKey: rootNavigatorKey,
    restorationScopeId: 'helpbari-router',
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final location = state.uri.path;
      final onboardingState = ref.read(onboardingViewModelProvider);
      final session = ref.read(authSessionProvider);
      final authState = ref.read(authViewModelProvider);
      final phase = AppRedirectResolver.phaseFor(
        session: session,
        authState: authState,
        onboardingState: onboardingState,
      );
      final isProtectedDestination =
          !AppRedirectResolver.isPublic(location) &&
          location != AppRoutes.onboarding;
      if (isProtectedDestination && phase != AppEntryPhase.ready) {
        pendingDestination = state.uri.toString();
        pendingUserId = session?.id;
      }
      if (session == null && pendingUserId != null) {
        pendingDestination = null;
        pendingUserId = null;
      } else if (session != null &&
          pendingUserId != null &&
          pendingUserId != session.id) {
        pendingDestination = null;
        pendingUserId = null;
      } else if (session != null && pendingDestination != null) {
        pendingUserId ??= session.id;
      }

      final resolved = AppRedirectResolver.resolve(
        location: location,
        session: session,
        onboardingState: onboardingState,
        authState: authState,
        profileState: ref.read(profileViewModelProvider),
      );
      if (phase == AppEntryPhase.ready &&
          pendingUserId == session?.id &&
          pendingDestination != null &&
          (resolved == AppRoutes.home ||
              location == AppRoutes.home ||
              AppRedirectResolver.isPublic(location))) {
        final destination = pendingDestination;
        pendingDestination = null;
        pendingUserId = null;
        return destination;
      }
      return resolved;
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.treatment,
                builder: (context, state) => const TreatmentPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MorePage(),
              ),
            ],
          ),
        ],
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
        redirect: (_, _) => AppRoutes.treatment,
      ),
      GoRoute(
        path: AppRoutes.registerVitamin,
        builder: (context, state) => RegisterVitaminPage(
          vitamin: state.extra is Vitamin ? state.extra! as Vitamin : null,
        ),
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
        builder: (context, state) => const MedicalExamsPage(),
      ),
      GoRoute(
        path: AppRoutes.registerExam,
        builder: (context, state) => RegisterMedicalExamPage(
          exam: state.extra is MedicalExam ? state.extra! as MedicalExam : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.examDetails,
        builder: (context, state) =>
            MedicalExamDetailsPage(exam: state.extra! as MedicalExam),
      ),
      GoRoute(
        path: AppRoutes.medications,
        redirect: (_, _) => AppRoutes.treatment,
      ),
      GoRoute(
        path: AppRoutes.registerMedication,
        builder: (context, state) => RegisterMedicationPage(
          medication: state.extra is Medication
              ? state.extra! as Medication
              : null,
        ),
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
        path: AppRoutes.prescriptions,
        builder: (_, _) => const MedicalPrescriptionsPage(),
      ),
      GoRoute(
        path: AppRoutes.documentCenter,
        builder: (_, _) => const DocumentCenterPage(),
      ),
      GoRoute(
        path: AppRoutes.newPrescription,
        builder: (_, _) => const RegisterMedicalPrescriptionPage(),
      ),
      GoRoute(
        path: AppRoutes.importPrescription,
        builder: (_, _) =>
            const RegisterMedicalPrescriptionPage(importDocument: true),
      ),
      GoRoute(
        path: AppRoutes.prescriptionDetails,
        builder: (_, state) => state.extra is MedicalPrescription
            ? MedicalPrescriptionDetailsPage(
                prescription: state.extra! as MedicalPrescription,
              )
            : MedicalPrescriptionRoutePage(
                id: state.pathParameters['id']!,
                mode: MedicalPrescriptionRouteMode.details,
              ),
      ),
      GoRoute(
        path: AppRoutes.editPrescription,
        builder: (_, state) => state.extra is MedicalPrescription
            ? RegisterMedicalPrescriptionPage(
                prescription: state.extra! as MedicalPrescription,
              )
            : MedicalPrescriptionRoutePage(
                id: state.pathParameters['id']!,
                mode: MedicalPrescriptionRouteMode.edit,
              ),
      ),
      GoRoute(
        path: AppRoutes.reviewPrescription,
        builder: (_, state) => state.extra is MedicalPrescription
            ? RegisterMedicalPrescriptionPage(
                prescription: state.extra! as MedicalPrescription,
                importDocument: true,
              )
            : MedicalPrescriptionRoutePage(
                id: state.pathParameters['id']!,
                mode: MedicalPrescriptionRouteMode.review,
              ),
      ),
      GoRoute(
        path: AppRoutes.addPrescriptionToRoutine,
        builder: (_, state) => state.extra is MedicalPrescription
            ? AddPrescriptionToRoutinePage(
                prescription: state.extra! as MedicalPrescription,
              )
            : MedicalPrescriptionRoutePage(
                id: state.pathParameters['id']!,
                mode: MedicalPrescriptionRouteMode.addToRoutine,
              ),
      ),
      GoRoute(
        path: AppRoutes.bioimpedance,
        builder: (context, state) => const BioimpedancePage(),
      ),
      GoRoute(
        path: AppRoutes.registerBioimpedance,
        builder: (context, state) => RegisterBioimpedancePage(
          record: state.extra is BioimpedanceRecord
              ? state.extra! as BioimpedanceRecord
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.bioimpedanceDetails,
        builder: (context, state) =>
            BioimpedanceDetailsPage(record: state.extra! as BioimpedanceRecord),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(path: AppRoutes.privacy, builder: (_, _) => const PrivacyPage()),
      GoRoute(path: AppRoutes.academy, builder: (_, _) => const AcademyPage()),
      GoRoute(
        path: AppRoutes.academyArticle,
        builder: (_, state) =>
            AcademyArticlePage(articleId: state.pathParameters['articleId']!),
      ),
      GoRoute(
        path: AppRoutes.academyFaq,
        builder: (_, _) => const AcademyFaqPage(),
      ),
      GoRoute(
        path: AppRoutes.academyGlossary,
        builder: (_, _) => const AcademyGlossaryPage(),
      ),
      GoRoute(
        path: AppRoutes.academyHistory,
        builder: (_, _) => const AcademyHistoryPage(),
      ),
    ],
  );

  final notificationTapSubscription = ref
      .read(notificationSchedulerProvider)
      .taps
      .listen((payload) async {
        final activeUserId = ref.read(authSessionProvider)?.id;
        if (activeUserId == null || payload.userId != activeUserId) return;
        if (payload.source == NotificationSource.smartRoutineOccurrence &&
            payload.action != 'open') {
          final action = RoutineNotificationActionType.values
              .where((value) => value.name == payload.action)
              .firstOrNull;
          if (action != null) {
            final now = ref.read(clockServiceProvider).now().toUtc();
            final repository = await ref.read(
              notificationPlatformRepositoryProvider.future,
            );
            await repository.receive(
              NotificationActionEnvelope(
                actionId:
                    payload.data['actionId'] ??
                    notificationActionId(payload, payload.action, null),
                userId: payload.userId,
                occurrenceId: payload.entityId,
                action: action,
                occurredAtUtc: now,
                receivedAtUtc: now,
              ),
            );
            await ref
                .read(notificationActionHandlerProvider.future)
                .then((handler) => handler.process(activeUserId));
          }
        }
        final location = notificationLocation(payload);
        if (location != null) router.go(location);
      });

  ref.onDispose(() {
    unawaited(notificationTapSubscription.cancel());
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

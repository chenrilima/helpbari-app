import 'package:go_router/go_router.dart';
import 'package:helpbari/features/meals/presentation/pages/meals_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/register_appointment_page.dart';
import '../../features/exams/presentation/pages/exams_page.dart';
import '../../features/exams/presentation/pages/register_exam_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/meals/presentation/pages/register_meal_page.dart';
import '../../features/medications/presentation/pages/medications_page.dart';
import '../../features/medications/presentation/pages/register_medication_page.dart';
import '../../features/profile/presentation/pages/complete_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/showcase/presentation/pages/showcase_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/vitamins/presentation/pages/register_vitamin_page.dart';
import '../../features/vitamins/presentation/pages/vitamins_page.dart';
import '../../features/water/presentation/pages/register_water_page.dart';
import '../../features/water/presentation/pages/water_page.dart';
import '../../features/weight/presentation/pages/register_weight_page.dart';
import '../../features/weight/presentation/pages/weight_page.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
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
      builder: (_, _) => const RegisterWeightPage(),
    ),
    GoRoute(path: AppRoutes.water, builder: (_, _) => const WaterPage()),
    GoRoute(
      path: AppRoutes.registerWater,
      builder: (_, _) => const RegisterWaterPage(),
    ),
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
      builder: (context, state) => const RegisterAppointmentPage(),
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
      builder: (context, state) => const RegisterExamPage(),
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
      path: AppRoutes.registerMeals,
      builder: (context, state) => const RegisterMealPage(),
    ),
  ],
);

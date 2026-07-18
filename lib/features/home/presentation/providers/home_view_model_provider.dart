import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/home_state.dart';
import '../viewmodels/home_view_model.dart';
import '../../domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';

final healthDashboardUseCasesProvider = Provider<HealthDashboardUseCases>((
  ref,
) {
  return HealthDashboardUseCases(
    profile: ref.watch(profileUseCasesProvider),
    weight: ref.watch(weightUseCasesProvider),
    water: ref.watch(waterUseCasesProvider),
    meals: ref.watch(mealUseCasesProvider),
    vitamins: ref.watch(vitaminUseCasesProvider),
    medications: ref.watch(medicationUseCasesProvider),
    appointments: ref.watch(appointmentUseCasesProvider),
    exams: ref.watch(medicalExamUseCasesProvider),
    settings: ref.watch(settingsUseCasesProvider),
  );
});

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

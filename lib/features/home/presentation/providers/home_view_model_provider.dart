import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/home_state.dart';
import '../viewmodels/home_view_model.dart';
import '../../domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';

final healthDashboardUseCasesProvider = Provider<HealthDashboardUseCases>((
  ref,
) {
  return HealthDashboardUseCases(
    profile: ref.watch(profileUseCasesProvider),
    weight: ref.watch(weightUseCasesProvider),
    water: ref.watch(waterUseCasesProvider),
    meals: ref.watch(mealUseCasesProvider),
    appointments: ref.watch(appointmentUseCasesProvider),
    exams: ref.watch(medicalExamUseCasesProvider),
    settings: ref.watch(settingsUseCasesProvider),
    treatment: () => ref.read(treatmentAdherenceQueryServiceProvider.future),
  );
});

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/health.dart';
import '../../../appointments/domain/models/appointment_summary.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../exams/domain/models/models.dart';
import '../../../exams/domain/usecases/use_cases.dart';
import '../../../exams/presentation/providers/exam_use_cases_provider.dart';
import '../../../meals/domain/models/meal_summary.dart';
import '../../../meals/domain/usecases/meal_use_cases.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medications/domain/models/models.dart';
import '../../../medications/domain/usecases/medication_use_cases.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/domain/entities/entities.dart';
import '../../../settings/domain/usecases/use_cases.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/domain/models/weight_summary.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  ProfileUseCases get _profileUseCases => ref.read(profileUseCasesProvider);
  WeightUseCases get _weightUseCases => ref.read(weightUseCasesProvider);
  WaterUseCases get _waterUseCases => ref.read(waterUseCasesProvider);
  VitaminUseCases get _vitaminUseCases => ref.read(vitaminUseCasesProvider);
  AppointmentUseCases get _appointmentUseCases =>
      ref.read(appointmentUseCasesProvider);
  ExamUseCases get _examUseCases => ref.read(examUseCasesProvider);
  MedicationUseCases get _medicationUseCases =>
      ref.read(medicationUseCasesProvider);
  MealUseCases get _mealUseCases => ref.read(mealUseCasesProvider);
  SettingsUseCases get _settingsUseCases => ref.read(settingsUseCasesProvider);

  @override
  HomeState build() => const HomeState();

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true);

    final results = await Future.wait([
      _profileUseCases.getProfile(),
      _weightUseCases.getSummary(),
      _waterUseCases.getTodayTotalInMl(),
      _vitaminUseCases.getPendingCount(),
      _appointmentUseCases.getSummary(),
      _examUseCases.getSummary(),
      _medicationUseCases.getSummary(),
      _mealUseCases.getSummary(),
      _settingsUseCases.getSettings(),
    ]);

    final profile = results[0] as Profile?;
    final weightSummary = results[1] as WeightSummary;
    final totalWaterToday = results[2] as int;
    final pendingVitamins = results[3] as int;
    final appointmentSummary = results[4] as AppointmentSummary;
    final examSummary = results[5] as ExamSummary;
    final medicationSummary = results[6] as MedicationSummary;
    final mealSummary = results[7] as MealSummary;
    final settings = results[8] as AppSettings;
    final currentWeight = weightSummary.latestRecord?.weight.value;
    final referenceWeight = currentWeight ?? profile?.initialWeight.value;
    final targetWeight = profile?.targetWeight?.value;
    final proteinGoal = referenceWeight == null
        ? 0
        : ProteinCalculator.goalForWeightKg(referenceWeight);
    final weightProgress =
        profile == null || currentWeight == null || targetWeight == null
        ? null
        : WeightProgressCalculator.calculate(
            initialWeightKg: profile.initialWeight.value,
            currentWeightKg: currentWeight,
            targetWeightKg: targetWeight,
          );
    final nextAppointment = appointmentSummary.nextAppointment;
    final latestExam = examSummary.latestExam;
    final dailySummary = DailySummaryCalculator.calculate(
      waterConsumedMl: totalWaterToday,
      waterGoalMl: settings.dailyWaterGoalMl,
      pendingVitamins: pendingVitamins,
      pendingMedications: medicationSummary.pendingCount,
      registeredMeals: mealSummary.todayCount,
      totalProteinGrams: mealSummary.totalProteinToday,
      proteinGoalGrams: proteinGoal,
      nextAppointment: nextAppointment == null
          ? null
          : DailySummaryItem(
              id: nextAppointment.id,
              title: nextAppointment.title,
              subtitle: nextAppointment.formattedDate,
              date: nextAppointment.date.value,
            ),
      latestExam: latestExam == null
          ? null
          : DailySummaryItem(
              id: latestExam.id,
              title: latestExam.formattedName,
              subtitle: latestExam.formattedDate,
              date: latestExam.examDate.value,
            ),
      weightProgress: weightProgress,
    );

    state = HomeState(
      profile: profile,
      latestWeightRecord: weightSummary.latestRecord,
      hasWeightRecords: weightSummary.hasRecords,
      totalWaterTodayInMl: totalWaterToday,
      pendingVitaminsCount: pendingVitamins,
      nextAppointment: appointmentSummary.nextAppointment,
      latestExam: examSummary.latestExam,
      isLoading: false,
      pendingMedicationsCount: medicationSummary.pendingCount,
      todayMealsCount: mealSummary.todayCount,
      totalProteinToday: mealSummary.totalProteinToday,
      dailySummary: dailySummary,
    );
  }
}

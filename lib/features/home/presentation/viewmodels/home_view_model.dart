import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/health.dart';
import '../../../../core/services/service_providers.dart';
import '../../domain/usecases/use_cases.dart';
import '../providers/home_view_model_provider.dart';
import '../states/home_state.dart';

class HomeViewModel extends Notifier<HomeState> {
  HealthDashboardUseCases get _dashboard =>
      ref.read(healthDashboardUseCasesProvider);

  @override
  HomeState build() => const HomeState();

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = ref.read(clockServiceProvider).now();
      final aggregate = await _dashboard.load(start: now, end: now);
      final today = aggregate.today;
      final profile = aggregate.profile;
      final currentWeight = aggregate.latestWeight?.weight.value;
      final proteinGoal = profile == null
          ? 0
          : ProteinCalculator.goalForWeightKg(
              currentWeight ?? profile.initialWeight.value,
            );
      final weightProgress =
          profile == null ||
              currentWeight == null ||
              profile.targetWeight == null
          ? null
          : WeightProgressCalculator.calculate(
              initialWeightKg: profile.initialWeight.value,
              currentWeightKg: currentWeight,
              targetWeightKg: profile.targetWeight!.value,
            );
      final dailySummary = DailySummary(
        hydration: HydrationCalculator.calculate(
          currentMl: today.waterMl ?? 0,
          goalMl: today.waterGoalMl ?? 0,
        ),
        pendingVitamins: today.pendingVitamins ?? 0,
        pendingMedications: today.pendingMedications ?? 0,
        registeredMeals: today.mealsCount ?? 0,
        protein: ProteinCalculator.calculate(
          currentGrams: today.proteinGrams ?? 0,
          goalGrams: proteinGoal,
        ),
        healthScore: today.healthScore,
        nextAppointment: aggregate.nextAppointment == null
            ? null
            : DailySummaryItem(
                id: aggregate.nextAppointment!.id,
                title: aggregate.nextAppointment!.title,
                subtitle: aggregate.nextAppointment!.formattedDate,
                date: aggregate.nextAppointment!.date.value,
              ),
        latestExam: aggregate.latestExam == null
            ? null
            : DailySummaryItem(
                id: aggregate.latestExam!.id,
                title: aggregate.latestExam!.formattedName,
                subtitle: aggregate.latestExam!.formattedDate,
                date: aggregate.latestExam!.examDate.value,
              ),
        weightProgress: weightProgress,
      );
      state = HomeState(
        profile: profile,
        latestWeightRecord: aggregate.latestWeight,
        hasWeightRecords: aggregate.latestWeight != null,
        totalWaterTodayInMl: today.waterMl ?? 0,
        pendingVitaminsCount: today.pendingVitamins ?? 0,
        nextAppointment: aggregate.nextAppointment,
        latestExam: aggregate.latestExam,
        pendingMedicationsCount: today.pendingMedications ?? 0,
        todayMealsCount: today.mealsCount ?? 0,
        totalProteinToday: today.proteinGrams ?? 0,
        dailySummary: dailySummary,
        unavailableSections: aggregate.unavailableSections,
        smartInsights: HealthInsightGenerator.generate(
          waterCurrentMl: today.waterMl ?? 0,
          waterGoalMl: today.waterGoalMl ?? 0,
          proteinCurrentGrams: today.proteinGrams ?? 0,
          proteinGoalGrams: proteinGoal,
          pendingVitamins: today.pendingVitamins ?? 0,
          pendingMedications: today.pendingMedications ?? 0,
        )..sort((a, b) => b.priority.index.compareTo(a.priority.index)),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar o dashboard local.',
      );
    }
  }
}

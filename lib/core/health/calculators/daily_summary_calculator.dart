import '../models/models.dart';
import 'health_score_calculator.dart';
import 'hydration_calculator.dart';
import 'protein_calculator.dart';

abstract final class DailySummaryCalculator {
  static DailySummary calculate({
    required int waterConsumedMl,
    required int waterGoalMl,
    required int pendingVitamins,
    required int pendingMedications,
    required int registeredMeals,
    required int totalProteinGrams,
    required int proteinGoalGrams,
    DailySummaryItem? nextAppointment,
    DailySummaryItem? latestExam,
    WeightProgressResult? weightProgress,
  }) {
    final hydration = HydrationCalculator.calculate(
      currentMl: waterConsumedMl,
      goalMl: waterGoalMl,
    );

    final protein = ProteinCalculator.calculate(
      currentGrams: totalProteinGrams,
      goalGrams: proteinGoalGrams,
    );

    final safePendingVitamins = _nonNegative(pendingVitamins);
    final safePendingMedications = _nonNegative(pendingMedications);
    final safeRegisteredMeals = _nonNegative(registeredMeals);

    final healthScore = HealthScoreCalculator.calculate(
      hydration: hydration,
      protein: protein,
      pendingVitamins: safePendingVitamins,
      pendingMedications: safePendingMedications,
      registeredMeals: safeRegisteredMeals,
      weightProgress: weightProgress,
    );

    return DailySummary(
      hydration: hydration,
      pendingVitamins: safePendingVitamins,
      pendingMedications: safePendingMedications,
      registeredMeals: safeRegisteredMeals,
      protein: protein,
      healthScore: healthScore,
      nextAppointment: nextAppointment,
      latestExam: latestExam,
      weightProgress: weightProgress,
    );
  }

  static int _nonNegative(int value) {
    return value < 0 ? 0 : value;
  }
}

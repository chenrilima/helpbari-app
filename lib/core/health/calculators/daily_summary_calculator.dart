import '../models/models.dart';
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
    return DailySummary(
      hydration: HydrationCalculator.calculate(
        currentMl: waterConsumedMl,
        goalMl: waterGoalMl,
      ),
      pendingVitamins: _nonNegative(pendingVitamins),
      pendingMedications: _nonNegative(pendingMedications),
      registeredMeals: _nonNegative(registeredMeals),
      protein: ProteinCalculator.calculate(
        currentGrams: totalProteinGrams,
        goalGrams: proteinGoalGrams,
      ),
      nextAppointment: nextAppointment,
      latestExam: latestExam,
      weightProgress: weightProgress,
    );
  }

  static int _nonNegative(int value) {
    return value < 0 ? 0 : value;
  }
}

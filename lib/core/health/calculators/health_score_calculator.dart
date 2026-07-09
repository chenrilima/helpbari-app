import '../models/models.dart';

abstract final class HealthScoreCalculator {
  static const hydrationWeight = 0.30;
  static const proteinWeight = 0.20;
  static const vitaminsWeight = 0.15;
  static const medicationsWeight = 0.15;
  static const mealsWeight = 0.10;
  static const weightProgressWeight = 0.10;

  static HealthScoreResult calculate({
    required HydrationResult hydration,
    required ProteinResult protein,
    required int pendingVitamins,
    required int pendingMedications,
    required int registeredMeals,
    WeightProgressResult? weightProgress,
  }) {
    final hydrationScore = hydration.progress * 100;
    final proteinScore = protein.progress * 100;
    final vitaminsScore = pendingVitamins == 0 ? 100.0 : 0.0;
    final medicationsScore = pendingMedications == 0 ? 100.0 : 0.0;
    final mealsScore = (registeredMeals / 3).clamp(0.0, 1.0) * 100;
    final weightProgressScore = (weightProgress?.progress ?? 0) * 100;

    final score =
        hydrationScore * hydrationWeight +
        proteinScore * proteinWeight +
        vitaminsScore * vitaminsWeight +
        medicationsScore * medicationsWeight +
        mealsScore * mealsWeight +
        weightProgressScore * weightProgressWeight;

    return HealthScoreResult(
      score: score.round().clamp(0, 100),
      hydrationScore: hydrationScore,
      proteinScore: proteinScore,
      vitaminsScore: vitaminsScore,
      medicationsScore: medicationsScore,
      mealsScore: mealsScore,
      weightProgressScore: weightProgressScore,
    );
  }
}

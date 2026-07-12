import '../models/models.dart';

abstract final class HealthScoreCalculator {
  static const hydrationWeight = 0.30;
  static const proteinWeight = 0.20;
  static const vitaminsWeight = 0.15;
  static const medicationsWeight = 0.15;
  static const mealsWeight = 0.10;
  static const weightProgressWeight = 0.10;

  /// Health Score 2.0 weights. Missing components are removed from the
  /// denominator, then the available weighted result is normalized to 0..100.
  /// This is a routine-tracking indicator and is not a clinical assessment.
  static const v2HydrationWeight = 0.25;
  static const v2ProteinWeight = 0.15;
  static const v2MealsWeight = 0.10;
  static const v2VitaminsWeight = 0.20;
  static const v2MedicationsWeight = 0.20;
  static const v2WeightWeight = 0.10;

  static HealthScoreResult calculateV2(HealthScoreInput input) {
    final components = <(double?, double)>[
      (input.hydration, v2HydrationWeight),
      (input.protein, v2ProteinWeight),
      (input.meals, v2MealsWeight),
      (input.vitamins, v2VitaminsWeight),
      (input.medications, v2MedicationsWeight),
      (input.weight, v2WeightWeight),
    ];
    var weightedTotal = 0.0;
    var availableWeight = 0.0;
    for (final component in components) {
      final value = component.$1;
      if (value == null) continue;
      weightedTotal += value.clamp(0, 1) * component.$2;
      availableWeight += component.$2;
    }
    final normalized = availableWeight == 0
        ? 0.0
        : weightedTotal / availableWeight * 100;
    return HealthScoreResult(
      score: normalized.round().clamp(0, 100),
      hydrationScore: (input.hydration ?? 0) * 100,
      proteinScore: (input.protein ?? 0) * 100,
      mealsScore: (input.meals ?? 0) * 100,
      vitaminsScore: (input.vitamins ?? 0) * 100,
      medicationsScore: (input.medications ?? 0) * 100,
      weightProgressScore: (input.weight ?? 0) * 100,
      availableWeight: availableWeight,
    );
  }

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

import '../models/models.dart';

abstract final class HealthScoreCalculator {
  static const hydrationWeight = 0.35;
  static const proteinWeight = 0.25;
  static const weightProgressWeight = 0.40;

  static HealthScoreResult calculate({
    required HydrationResult hydration,
    required ProteinResult protein,
    required WeightProgressResult weightProgress,
  }) {
    final hydrationScore = hydration.progress * 100;
    final proteinScore = protein.progress * 100;
    final weightProgressScore = weightProgress.progress * 100;

    final score =
        hydrationScore * hydrationWeight +
        proteinScore * proteinWeight +
        weightProgressScore * weightProgressWeight;

    return HealthScoreResult(
      score: score.round().clamp(0, 100),
      hydrationScore: hydrationScore,
      proteinScore: proteinScore,
      weightProgressScore: weightProgressScore,
    );
  }
}

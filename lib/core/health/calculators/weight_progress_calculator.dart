import '../models/models.dart';

abstract final class WeightProgressCalculator {
  static WeightProgressResult calculate({
    required double initialWeightKg,
    required double currentWeightKg,
    required double targetWeightKg,
  }) {
    final totalToLose = initialWeightKg - targetWeightKg;
    final weightLostKg = initialWeightKg - currentWeightKg;
    final remainingKg = currentWeightKg - targetWeightKg;
    final progress = totalToLose <= 0 ? 0 : weightLostKg / totalToLose;

    return WeightProgressResult(
      initialWeightKg: initialWeightKg,
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      weightLostKg: weightLostKg,
      remainingKg: remainingKg > 0 ? remainingKg : 0,
      progress: progress.clamp(0, 1).toDouble(),
      isTargetReached: currentWeightKg <= targetWeightKg,
    );
  }
}

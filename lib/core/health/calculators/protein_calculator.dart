import '../models/models.dart';

abstract final class ProteinCalculator {
  static const defaultGramsPerKg = 1.2;

  static int goalForWeightKg(
    num weightKg, {
    double gramsPerKg = defaultGramsPerKg,
  }) {
    if (weightKg <= 0 || gramsPerKg <= 0) return 0;

    return (weightKg * gramsPerKg).round();
  }

  static ProteinResult calculate({
    required int currentGrams,
    required int goalGrams,
  }) {
    final safeCurrentGrams = currentGrams < 0 ? 0 : currentGrams;
    final safeGoalGrams = goalGrams < 0 ? 0 : goalGrams;
    final progress = _progress(safeCurrentGrams, safeGoalGrams);
    final remainingGrams = safeGoalGrams - safeCurrentGrams;

    return ProteinResult(
      currentGrams: safeCurrentGrams,
      goalGrams: safeGoalGrams,
      progress: progress,
      remainingGrams: remainingGrams > 0 ? remainingGrams : 0,
      isGoalReached: safeGoalGrams > 0 && safeCurrentGrams >= safeGoalGrams,
    );
  }

  static double _progress(int current, int goal) {
    if (goal <= 0) return 0;

    return (current / goal).clamp(0, 1).toDouble();
  }
}

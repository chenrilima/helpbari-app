import '../models/models.dart';

abstract final class HydrationCalculator {
  static const defaultMlPerKg = 35;

  static int goalForWeightKg(num weightKg, {int mlPerKg = defaultMlPerKg}) {
    if (weightKg <= 0 || mlPerKg <= 0) return 0;

    return (weightKg * mlPerKg).round();
  }

  static HydrationResult calculate({
    required int currentMl,
    required int goalMl,
  }) {
    final safeCurrentMl = currentMl < 0 ? 0 : currentMl;
    final safeGoalMl = goalMl < 0 ? 0 : goalMl;
    final progress = _progress(safeCurrentMl, safeGoalMl);
    final remainingMl = safeGoalMl - safeCurrentMl;

    return HydrationResult(
      currentMl: safeCurrentMl,
      goalMl: safeGoalMl,
      progress: progress,
      remainingMl: remainingMl > 0 ? remainingMl : 0,
      isGoalReached: safeGoalMl > 0 && safeCurrentMl >= safeGoalMl,
    );
  }

  static double _progress(int current, int goal) {
    if (goal <= 0) return 0;

    return (current / goal).clamp(0, 1).toDouble();
  }
}

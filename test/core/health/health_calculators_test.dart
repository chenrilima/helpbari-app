import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';

void main() {
  group('HydrationCalculator', () {
    test('calculates goal from weight', () {
      final goal = HydrationCalculator.goalForWeightKg(80);

      expect(goal, 2800);
    });

    test('calculates progress and remaining hydration', () {
      final result = HydrationCalculator.calculate(
        currentMl: 1500,
        goalMl: 2000,
      );

      expect(result.currentMl, 1500);
      expect(result.goalMl, 2000);
      expect(result.progress, 0.75);
      expect(result.remainingMl, 500);
      expect(result.isGoalReached, isFalse);
    });

    test('clamps hydration progress when goal is exceeded', () {
      final result = HydrationCalculator.calculate(
        currentMl: 2500,
        goalMl: 2000,
      );

      expect(result.progress, 1);
      expect(result.remainingMl, 0);
      expect(result.isGoalReached, isTrue);
    });
  });

  group('ProteinCalculator', () {
    test('calculates goal from weight', () {
      final goal = ProteinCalculator.goalForWeightKg(80);

      expect(goal, 96);
    });

    test('calculates progress and remaining protein', () {
      final result = ProteinCalculator.calculate(
        currentGrams: 40,
        goalGrams: 100,
      );

      expect(result.currentGrams, 40);
      expect(result.goalGrams, 100);
      expect(result.progress, 0.4);
      expect(result.remainingGrams, 60);
      expect(result.isGoalReached, isFalse);
    });
  });

  group('WeightProgressCalculator', () {
    test('calculates weight loss progress', () {
      final result = WeightProgressCalculator.calculate(
        initialWeightKg: 120,
        currentWeightKg: 100,
        targetWeightKg: 80,
      );

      expect(result.weightLostKg, 20);
      expect(result.remainingKg, 20);
      expect(result.progress, 0.5);
      expect(result.isTargetReached, isFalse);
    });

    test('clamps progress when target is reached', () {
      final result = WeightProgressCalculator.calculate(
        initialWeightKg: 120,
        currentWeightKg: 78,
        targetWeightKg: 80,
      );

      expect(result.remainingKg, 0);
      expect(result.progress, 1);
      expect(result.isTargetReached, isTrue);
    });
  });

  group('HealthScoreCalculator', () {
    test('calculates weighted health score', () {
      const hydration = HydrationResult(
        currentMl: 2000,
        goalMl: 2000,
        progress: 1,
        remainingMl: 0,
        isGoalReached: true,
      );
      const protein = ProteinResult(
        currentGrams: 50,
        goalGrams: 100,
        progress: 0.5,
        remainingGrams: 50,
        isGoalReached: false,
      );
      const weightProgress = WeightProgressResult(
        initialWeightKg: 120,
        currentWeightKg: 100,
        targetWeightKg: 80,
        weightLostKg: 20,
        remainingKg: 20,
        progress: 0.5,
        isTargetReached: false,
      );

      final result = HealthScoreCalculator.calculate(
        hydration: hydration,
        protein: protein,
        weightProgress: weightProgress,
      );

      expect(result.score, 68);
      expect(result.isExcellent, isFalse);
    });
  });
}

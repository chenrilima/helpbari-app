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
    test('v2 normalizes only available components and preserves zero', () {
      final result = HealthScoreCalculator.calculateV2(
        const HealthScoreInput(hydration: 0, vitamins: 0),
      );

      expect(result.score, 0);
      expect(result.hasData, isTrue);
      expect(result.availableWeight, 0.45);
    });

    test('v2 does not treat missing data as failure', () {
      final result = HealthScoreCalculator.calculateV2(
        const HealthScoreInput(hydration: 1),
      );

      expect(result.score, 100);
      expect(result.availableWeight, HealthScoreCalculator.v2HydrationWeight);
    });

    test('v2 returns unavailable zero when every component is absent', () {
      final result = HealthScoreCalculator.calculateV2(
        const HealthScoreInput(),
      );

      expect(result.score, 0);
      expect(result.hasData, isFalse);
    });
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
        pendingVitamins: 1,
        pendingMedications: 0,
        registeredMeals: 3,
        weightProgress: weightProgress,
      );

      expect(result.score, 70);
      expect(result.isExcellent, isFalse);
    });
  });

  group('DailySummaryCalculator', () {
    test('aggregates daily health data', () {
      const nextAppointment = DailySummaryItem(
        id: 'appointment-1',
        title: 'Retorno médico',
        subtitle: '10:00',
      );
      const latestExam = DailySummaryItem(id: 'exam-1', title: 'Hemograma');
      const weightProgress = WeightProgressResult(
        initialWeightKg: 120,
        currentWeightKg: 100,
        targetWeightKg: 80,
        weightLostKg: 20,
        remainingKg: 20,
        progress: 0.5,
        isTargetReached: false,
      );

      final summary = DailySummaryCalculator.calculate(
        waterConsumedMl: 1500,
        waterGoalMl: 2000,
        pendingVitamins: 1,
        pendingMedications: 2,
        registeredMeals: 3,
        totalProteinGrams: 60,
        proteinGoalGrams: 100,
        nextAppointment: nextAppointment,
        latestExam: latestExam,
        weightProgress: weightProgress,
      );

      expect(summary.waterConsumedMl, 1500);
      expect(summary.waterGoalMl, 2000);
      expect(summary.hydration.progress, 0.75);
      expect(summary.pendingVitamins, 1);
      expect(summary.pendingMedications, 2);
      expect(summary.registeredMeals, 3);
      expect(summary.totalProteinGrams, 60);
      expect(summary.protein.progress, 0.6);
      expect(summary.nextAppointment, nextAppointment);
      expect(summary.latestExam, latestExam);
      expect(summary.weightProgress, weightProgress);
    });

    test('clamps negative counters', () {
      final summary = DailySummaryCalculator.calculate(
        waterConsumedMl: -1,
        waterGoalMl: -1,
        pendingVitamins: -1,
        pendingMedications: -1,
        registeredMeals: -1,
        totalProteinGrams: -1,
        proteinGoalGrams: -1,
      );

      expect(summary.waterConsumedMl, 0);
      expect(summary.waterGoalMl, 0);
      expect(summary.pendingVitamins, 0);
      expect(summary.pendingMedications, 0);
      expect(summary.registeredMeals, 0);
      expect(summary.totalProteinGrams, 0);
      expect(summary.proteinGoalGrams, 0);
    });
  });
}

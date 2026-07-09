import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';

void main() {
  group('HealthInsightGenerator', () {
    test('creates hydration insight for low water intake', () {
      final insight = HealthInsightGenerator.hydration(
        currentMl: 500,
        goalMl: 2000,
      );

      expect(insight.title, 'Hidratação baixa');
      expect(insight.type, InsightType.hydration);
      expect(insight.priority, InsightPriority.high);
    });

    test('creates protein insight when goal is reached', () {
      final insight = HealthInsightGenerator.protein(
        currentGrams: 100,
        goalGrams: 90,
      );

      expect(insight.title, 'Proteína em dia');
      expect(insight.type, InsightType.protein);
      expect(insight.priority, InsightPriority.low);
    });

    test('creates vitamin insight for pending vitamins', () {
      final insight = HealthInsightGenerator.vitamins(pendingCount: 2);

      expect(insight.title, 'Vitaminas pendentes');
      expect(
        insight.message,
        'Você ainda tem 2 vitaminas para registrar hoje.',
      );
      expect(insight.type, InsightType.vitamin);
      expect(insight.priority, InsightPriority.high);
    });

    test('creates medication insight for pending medication', () {
      final insight = HealthInsightGenerator.medications(pendingCount: 1);

      expect(insight.title, 'Medicamento pendente');
      expect(
        insight.message,
        'Você ainda tem 1 medicamento para registrar hoje.',
      );
      expect(insight.type, InsightType.medication);
      expect(insight.priority, InsightPriority.high);
    });

    test('generates initial dashboard insights', () {
      final insights = HealthInsightGenerator.generate(
        waterCurrentMl: 2000,
        waterGoalMl: 2000,
        proteinCurrentGrams: 40,
        proteinGoalGrams: 100,
        pendingVitamins: 0,
        pendingMedications: 2,
      );

      expect(insights, hasLength(4));
      expect(insights.map((insight) => insight.type), [
        InsightType.hydration,
        InsightType.protein,
        InsightType.vitamin,
        InsightType.medication,
      ]);
    });
  });
}

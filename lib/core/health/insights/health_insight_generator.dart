import 'insight.dart';

abstract final class HealthInsightGenerator {
  static List<Insight> generate({
    required int waterCurrentMl,
    required int waterGoalMl,
    required int proteinCurrentGrams,
    required int proteinGoalGrams,
    required int pendingVitamins,
    required int pendingMedications,
  }) {
    return [
      hydration(currentMl: waterCurrentMl, goalMl: waterGoalMl),
      protein(currentGrams: proteinCurrentGrams, goalGrams: proteinGoalGrams),
      vitamins(pendingCount: pendingVitamins),
      medications(pendingCount: pendingMedications),
    ];
  }

  static Insight hydration({required int currentMl, required int goalMl}) {
    final progress = _progress(currentMl, goalMl);

    if (goalMl <= 0) {
      return const Insight(
        title: 'Meta de água não definida',
        message: 'Defina uma meta diária para acompanhar sua hidratação.',
        type: InsightType.hydration,
        priority: InsightPriority.medium,
      );
    }

    if (progress >= 1) {
      return const Insight(
        title: 'Hidratação em dia',
        message: 'Você atingiu sua meta de água hoje.',
        type: InsightType.hydration,
        priority: InsightPriority.low,
      );
    }

    if (progress >= 0.6) {
      return const Insight(
        title: 'Continue bebendo água',
        message: 'Você está perto da sua meta diária de hidratação.',
        type: InsightType.hydration,
        priority: InsightPriority.medium,
      );
    }

    return const Insight(
      title: 'Hidratação baixa',
      message: 'Sua ingestão de água está abaixo do esperado para hoje.',
      type: InsightType.hydration,
      priority: InsightPriority.high,
    );
  }

  static Insight protein({required int currentGrams, required int goalGrams}) {
    final progress = _progress(currentGrams, goalGrams);

    if (goalGrams <= 0) {
      return const Insight(
        title: 'Meta de proteína não definida',
        message:
            'Defina uma meta para acompanhar melhor sua ingestão proteica.',
        type: InsightType.protein,
        priority: InsightPriority.medium,
      );
    }

    if (progress >= 1) {
      return const Insight(
        title: 'Proteína em dia',
        message: 'Você atingiu sua meta de proteína hoje.',
        type: InsightType.protein,
        priority: InsightPriority.low,
      );
    }

    if (progress >= 0.5) {
      return const Insight(
        title: 'Proteína quase lá',
        message: 'Inclua proteína nas próximas refeições para fechar sua meta.',
        type: InsightType.protein,
        priority: InsightPriority.medium,
      );
    }

    return const Insight(
      title: 'Proteína baixa',
      message: 'Sua ingestão de proteína está baixa hoje.',
      type: InsightType.protein,
      priority: InsightPriority.high,
    );
  }

  static Insight vitamins({required int pendingCount}) {
    if (pendingCount <= 0) {
      return const Insight(
        title: 'Vitaminas em dia',
        message: 'Você não tem vitaminas pendentes hoje.',
        type: InsightType.vitamin,
        priority: InsightPriority.low,
      );
    }

    if (pendingCount == 1) {
      return const Insight(
        title: 'Vitamina pendente',
        message: 'Você ainda tem 1 vitamina para registrar hoje.',
        type: InsightType.vitamin,
        priority: InsightPriority.medium,
      );
    }

    return Insight(
      title: 'Vitaminas pendentes',
      message: 'Você ainda tem $pendingCount vitaminas para registrar hoje.',
      type: InsightType.vitamin,
      priority: InsightPriority.high,
    );
  }

  static Insight medications({required int pendingCount}) {
    if (pendingCount <= 0) {
      return const Insight(
        title: 'Medicamentos em dia',
        message: 'Você não tem medicamentos pendentes hoje.',
        type: InsightType.medication,
        priority: InsightPriority.low,
      );
    }

    if (pendingCount == 1) {
      return const Insight(
        title: 'Medicamento pendente',
        message: 'Você ainda tem 1 medicamento para registrar hoje.',
        type: InsightType.medication,
        priority: InsightPriority.high,
      );
    }

    return Insight(
      title: 'Medicamentos pendentes',
      message: 'Você ainda tem $pendingCount medicamentos para registrar hoje.',
      type: InsightType.medication,
      priority: InsightPriority.high,
    );
  }

  static double _progress(int current, int goal) {
    if (goal <= 0) return 0;

    return (current / goal).clamp(0, 1).toDouble();
  }
}

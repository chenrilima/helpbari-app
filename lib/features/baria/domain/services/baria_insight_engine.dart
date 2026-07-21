import '../../../home/domain/models/home_intelligence_models.dart';
import '../models/models.dart';

/// Presentation-neutral adapter. Insight decisions remain exclusively in
/// DeterministicInsightEngine and are never recalculated by BarIA.
class BariaInsightEngine {
  const BariaInsightEngine();

  List<BariaInsight> generate(BariaContext context) {
    final intelligence = context.intelligence;
    if (intelligence == null || intelligence.userId != context.userId) {
      return const [];
    }
    return List.unmodifiable(
      intelligence.insights.insights.map(
        (value) => BariaInsight(
          id: value.id,
          title: value.title,
          message: '${value.message} ${value.disclaimer}',
          createdAt: context.generatedAt,
          priority: _priority(value.priority),
          category: _category(value.sources.firstOrNull),
          action: value.deepLink == null
              ? const BariaInsightAction.none()
              : BariaInsightAction(
                  type: BariaInsightActionType.route,
                  label: 'Abrir',
                  destination: value.deepLink,
                ),
          source: value.ruleId,
        ),
      ),
    );
  }

  BariaInsightPriority _priority(InsightPriority value) => switch (value) {
    InsightPriority.critical => BariaInsightPriority.critical,
    InsightPriority.high => BariaInsightPriority.high,
    InsightPriority.medium => BariaInsightPriority.medium,
    InsightPriority.low => BariaInsightPriority.low,
  };

  BariaInsightCategory _category(String? source) => switch (source) {
    'water' => BariaInsightCategory.water,
    'meals' => BariaInsightCategory.nutrition,
    'weight' => BariaInsightCategory.weight,
    'appointments' => BariaInsightCategory.appointments,
    'prescriptions' => BariaInsightCategory.prescriptions,
    'smartRoutines' => BariaInsightCategory.medications,
    _ => BariaInsightCategory.general,
  };
}

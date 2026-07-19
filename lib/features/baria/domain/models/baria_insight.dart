enum BariaInsightPriority { critical, high, medium, low }

enum BariaInsightCategory {
  health,
  water,
  weight,
  nutrition,
  vitamins,
  medications,
  prescriptions,
  appointments,
  academy,
  reports,
  general,
}

enum BariaInsightActionType { route, article, faq, glossary, none }

class BariaInsightAction {
  const BariaInsightAction({
    required this.type,
    required this.label,
    this.destination,
  });

  const BariaInsightAction.none()
    : type = BariaInsightActionType.none,
      label = '',
      destination = null;

  final BariaInsightActionType type;
  final String label;
  final String? destination;
}

class BariaInsight {
  const BariaInsight({
    required this.id,
    required this.title,
    required String message,
    required this.createdAt,
    this.priority = BariaInsightPriority.low,
    this.category = BariaInsightCategory.general,
    this.action = const BariaInsightAction.none(),
    this.source = 'HelpBari',
    this.healthScoreImprovement,
  }) : description = message;

  final String id;
  final String title;
  final String description;
  final BariaInsightPriority priority;
  final BariaInsightCategory category;
  final BariaInsightAction action;
  final String source;
  final DateTime createdAt;
  final double? healthScoreImprovement;

  String get message => description;
}

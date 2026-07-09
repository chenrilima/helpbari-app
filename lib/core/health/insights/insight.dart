enum InsightType { hydration, protein, vitamin, medication }

enum InsightPriority { low, medium, high }

class Insight {
  const Insight({
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
  });

  final String title;
  final String message;
  final InsightType type;
  final InsightPriority priority;
}

class HealthScoreResult {
  const HealthScoreResult({
    required this.score,
    required this.hydrationScore,
    required this.proteinScore,
    required this.weightProgressScore,
  });

  final int score;
  final double hydrationScore;
  final double proteinScore;
  final double weightProgressScore;

  bool get isExcellent => score >= 80;
}

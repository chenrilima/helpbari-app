class ProteinResult {
  const ProteinResult({
    required this.currentGrams,
    required this.goalGrams,
    required this.progress,
    required this.remainingGrams,
    required this.isGoalReached,
  });

  final int currentGrams;
  final int goalGrams;
  final double progress;
  final int remainingGrams;
  final bool isGoalReached;
}

class HydrationResult {
  const HydrationResult({
    required this.currentMl,
    required this.goalMl,
    required this.progress,
    required this.remainingMl,
    required this.isGoalReached,
  });

  final int currentMl;
  final int goalMl;
  final double progress;
  final int remainingMl;
  final bool isGoalReached;
}

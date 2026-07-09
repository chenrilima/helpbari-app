class WeightProgressResult {
  const WeightProgressResult({
    required this.initialWeightKg,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.weightLostKg,
    required this.remainingKg,
    required this.progress,
    required this.isTargetReached,
  });

  final double initialWeightKg;
  final double currentWeightKg;
  final double targetWeightKg;
  final double weightLostKg;
  final double remainingKg;
  final double progress;
  final bool isTargetReached;
}

class HealthScoreInput {
  const HealthScoreInput({
    this.hydration,
    this.protein,
    this.meals,
    this.vitamins,
    this.medications,
    this.weight,
  });

  final double? hydration;
  final double? protein;
  final double? meals;
  final double? vitamins;
  final double? medications;
  final double? weight;
}

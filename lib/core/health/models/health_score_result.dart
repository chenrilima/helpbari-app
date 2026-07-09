class HealthScoreResult {
  const HealthScoreResult({
    required this.score,
    required this.hydrationScore,
    required this.proteinScore,
    required this.vitaminsScore,
    required this.medicationsScore,
    required this.mealsScore,
    required this.weightProgressScore,
  });

  final int score;
  final double hydrationScore;
  final double proteinScore;
  final double vitaminsScore;
  final double medicationsScore;
  final double mealsScore;
  final double weightProgressScore;

  bool get isExcellent => score >= 80;

  bool get isGood => score >= 60 && score < 80;

  String get label {
    if (isExcellent) return 'Excelente';
    if (isGood) return 'Boa rotina';

    return 'Em evolução';
  }

  String get message {
    if (isExcellent) {
      return 'Sua rotina está muito bem hoje.';
    }

    if (isGood) {
      return 'Você está no caminho certo.';
    }

    return 'Pequenos registros já ajudam sua evolução.';
  }
}

import '../entities/entities.dart';

class MealSummary {
  const MealSummary({
    required this.latestMeal,
    required this.todayCount,
    required this.totalProteinToday,
    required this.hasMeals,
  });

  final Meal? latestMeal;
  final int todayCount;
  final int totalProteinToday;
  final bool hasMeals;

  String get formattedTodayCount {
    if (todayCount == 0) return 'Nenhuma refeição hoje';

    if (todayCount == 1) return '1 refeição hoje';

    return '$todayCount refeições hoje';
  }

  String get formattedProteinToday {
    if (totalProteinToday <= 0) return 'Proteína não informada';

    return '$totalProteinToday g de proteína hoje';
  }
}

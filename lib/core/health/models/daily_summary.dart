import 'daily_summary_item.dart';
import 'hydration_result.dart';
import 'protein_result.dart';
import 'weight_progress_result.dart';

class DailySummary {
  const DailySummary({
    required this.hydration,
    required this.pendingVitamins,
    required this.pendingMedications,
    required this.registeredMeals,
    required this.protein,
    this.nextAppointment,
    this.latestExam,
    this.weightProgress,
  });

  final HydrationResult hydration;
  final int pendingVitamins;
  final int pendingMedications;
  final int registeredMeals;
  final ProteinResult protein;
  final DailySummaryItem? nextAppointment;
  final DailySummaryItem? latestExam;
  final WeightProgressResult? weightProgress;

  int get waterConsumedMl => hydration.currentMl;

  int get waterGoalMl => hydration.goalMl;

  int get totalProteinGrams => protein.currentGrams;

  int get proteinGoalGrams => protein.goalGrams;

  bool get hasPendingVitamins => pendingVitamins > 0;

  bool get hasPendingMedications => pendingMedications > 0;

  bool get hasRegisteredMeals => registeredMeals > 0;

  bool get hasNextAppointment => nextAppointment != null;

  bool get hasLatestExam => latestExam != null;

  bool get hasWeightProgress => weightProgress != null;
}

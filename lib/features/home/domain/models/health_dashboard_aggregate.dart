import '../../../../core/health/health.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';

enum HealthDataSection {
  profile,
  settings,
  weight,
  water,
  meals,
  vitamins,
  medications,
  appointments,
  exams,
}

class DailyHealthAggregate {
  const DailyHealthAggregate({
    required this.date,
    required this.waterMl,
    required this.waterGoalMl,
    required this.mealsCount,
    required this.proteinGrams,
    required this.vitaminAdherence,
    required this.medicationAdherence,
    required this.weightKg,
    required this.healthScore,
    required this.pendingVitamins,
    required this.pendingMedications,
  });
  final DateTime date;
  final int? waterMl;
  final int? waterGoalMl;
  final int? mealsCount;
  final int? proteinGrams;
  final double? vitaminAdherence;
  final double? medicationAdherence;
  final double? weightKg;
  final HealthScoreResult healthScore;
  final int? pendingVitamins;
  final int? pendingMedications;
}

class HealthDashboardAggregate {
  const HealthDashboardAggregate({
    required this.periodStart,
    required this.periodEnd,
    required this.days,
    required this.unavailableSections,
    this.profile,
    this.latestWeight,
    this.nextAppointment,
    this.latestExam,
  });
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<DailyHealthAggregate> days;
  final Set<HealthDataSection> unavailableSections;
  final Profile? profile;
  final WeightRecord? latestWeight;
  final Appointment? nextAppointment;
  final MedicalExam? latestExam;

  DailyHealthAggregate get today => days.last;
  bool isAvailable(HealthDataSection section) =>
      !unavailableSections.contains(section);
}

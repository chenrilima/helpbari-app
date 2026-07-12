import '../../../../core/health/health.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../exams/domain/entities/entities.dart';
import '../../../meals/domain/entities/entities.dart';
import '../../../medications/domain/entities/entities.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../vitamins/domain/entities/entities.dart';
import '../../../water/domain/entities/entities.dart';
import '../../../weight/domain/entities/entities.dart';
import '../entities/entities.dart';

class MedicalReportSnapshot {
  const MedicalReportSnapshot({
    required this.generatedAt,
    required this.template,
    required this.weightHistory,
    required this.waterHistory,
    required this.vitamins,
    required this.vitaminLogs,
    required this.medications,
    required this.medicationLogs,
    required this.meals,
    required this.appointments,
    required this.exams,
    required this.dailySummary,
    required this.reportVersion,
    required this.periodStart,
    required this.averageDailyWaterMl,
    required this.mealsInPeriod,
    required this.averageDailyProteinGrams,
    required this.vitaminAdherencePercent,
    required this.medicationAdherencePercent,
    required this.automaticObservations,
    this.profile,
    this.attachments = const [],
  });

  final DateTime generatedAt;
  final ReportTemplate template;
  final Profile? profile;
  final List<WeightRecord> weightHistory;
  final List<WaterRecord> waterHistory;
  final List<Vitamin> vitamins;
  final List<VitaminLog> vitaminLogs;
  final List<Medication> medications;
  final List<MedicationLog> medicationLogs;
  final List<Meal> meals;
  final List<Appointment> appointments;
  final List<Exam> exams;
  final DailySummary dailySummary;
  final String reportVersion;
  final DateTime periodStart;
  final int averageDailyWaterMl;
  final int mealsInPeriod;
  final int averageDailyProteinGrams;
  final double? vitaminAdherencePercent;
  final double? medicationAdherencePercent;
  final List<String> automaticObservations;
  final List<ReportAttachment> attachments;

  WeightRecord? get latestWeight {
    return weightHistory.isEmpty ? null : weightHistory.first;
  }

  int get totalWaterTodayInMl => dailySummary.waterConsumedMl;

  int get pendingVitamins => dailySummary.pendingVitamins;

  int get pendingMedications => dailySummary.pendingMedications;

  bool get hasClinicalData =>
      profile != null ||
      weightHistory.isNotEmpty ||
      waterHistory.isNotEmpty ||
      meals.isNotEmpty ||
      vitamins.isNotEmpty ||
      medications.isNotEmpty ||
      appointments.isNotEmpty ||
      exams.isNotEmpty;

  List<Appointment> get upcomingAppointments =>
      appointments.where((appointment) => appointment.isUpcoming).toList();

  List<Exam> get latestExams => exams.take(10).toList();
}

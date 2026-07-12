import '../../../../core/health/health.dart';
import '../../../../core/services/services.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../exams/domain/usecases/use_cases.dart';
import '../../../meals/domain/usecases/use_cases.dart';
import '../../../medications/domain/usecases/use_cases.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../settings/domain/entities/entities.dart';
import '../../../settings/domain/usecases/use_cases.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../water/domain/entities/entities.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class MedicalReportUseCases {
  const MedicalReportUseCases({
    required MedicalReportRepository repository,
    required ProfileUseCases profileUseCases,
    required WeightUseCases weightUseCases,
    required WaterUseCases waterUseCases,
    required VitaminUseCases vitaminUseCases,
    required MedicationUseCases medicationUseCases,
    required MealUseCases mealUseCases,
    required AppointmentUseCases appointmentUseCases,
    required ExamUseCases examUseCases,
    required SettingsUseCases settingsUseCases,
    required ClockService clock,
  }) : _repository = repository,
       _profileUseCases = profileUseCases,
       _weightUseCases = weightUseCases,
       _waterUseCases = waterUseCases,
       _vitaminUseCases = vitaminUseCases,
       _medicationUseCases = medicationUseCases,
       _mealUseCases = mealUseCases,
       _appointmentUseCases = appointmentUseCases,
       _examUseCases = examUseCases,
       _settingsUseCases = settingsUseCases,
       _clock = clock;

  final MedicalReportRepository _repository;
  final ProfileUseCases _profileUseCases;
  final WeightUseCases _weightUseCases;
  final WaterUseCases _waterUseCases;
  final VitaminUseCases _vitaminUseCases;
  final MedicationUseCases _medicationUseCases;
  final MealUseCases _mealUseCases;
  final AppointmentUseCases _appointmentUseCases;
  final ExamUseCases _examUseCases;
  final SettingsUseCases _settingsUseCases;
  final ClockService _clock;

  Future<GeneratedMedicalReport> generateCompleteReport({
    ReportTemplate? template,
    List<ReportAttachment> attachments = const [],
  }) async {
    final selectedTemplate = template ?? ReportTemplate.complete();
    final snapshot = await buildSnapshot(
      template: selectedTemplate,
      attachments: attachments,
    );

    return _repository.generate(snapshot: snapshot, template: selectedTemplate);
  }

  Future<MedicalReportSnapshot> buildSnapshot({
    required ReportTemplate template,
    List<ReportAttachment> attachments = const [],
  }) async {
    final results = await Future.wait([
      _profileUseCases.getProfile(),
      _weightUseCases.getHistory(),
      _waterUseCases.getHistory(),
      _vitaminUseCases.getAll(),
      _medicationUseCases.getAll(),
      _mealUseCases.getAll(),
      _appointmentUseCases.getAll(),
      _examUseCases.getAll(),
      _settingsUseCases.getSettings(),
      _vitaminUseCases.getLogs(
        DateTime(_clock.now().year, _clock.now().month, _clock.now().day),
        DateTime(_clock.now().year, _clock.now().month, _clock.now().day),
      ),
    ]);

    final profile = results[0] as Profile?;
    final weightHistory = results[1] as List;
    final waterHistory = results[2] as List<WaterRecord>;
    final vitamins = results[3] as List;
    final medications = results[4] as List;
    final meals = results[5] as List;
    final appointments = results[6] as List;
    final exams = results[7] as List;
    final settings = results[8] as AppSettings;
    final vitaminLogs = results[9] as List;
    final now = _clock.now();
    final currentWeight = weightHistory.isEmpty
        ? null
        : weightHistory.first.weight.value as double;
    final referenceWeight = currentWeight ?? profile?.initialWeight.value;
    final targetWeight = profile?.targetWeight?.value;
    final proteinGoal = referenceWeight == null
        ? 0
        : ProteinCalculator.goalForWeightKg(referenceWeight);
    final totalWaterToday = waterHistory
        .where((record) => _isSameDay(record.recordedAt, now))
        .fold<int>(0, (total, record) => total + record.amount.valueInMl);
    final todayMeals = meals.where((meal) => meal.wasRegisteredToday).toList();
    final totalProteinToday = todayMeals.fold<int>(
      0,
      (total, meal) => total + ((meal.proteinGrams as int?) ?? 0),
    );
    final upcomingAppointments = appointments
        .where((appointment) => appointment.isUpcoming)
        .toList();
    final weightProgress =
        profile == null || currentWeight == null || targetWeight == null
        ? null
        : WeightProgressCalculator.calculate(
            initialWeightKg: profile.initialWeight.value,
            currentWeightKg: currentWeight,
            targetWeightKg: targetWeight,
          );
    final latestExam = exams.isEmpty ? null : exams.first;
    final nextAppointment = upcomingAppointments.isEmpty
        ? null
        : upcomingAppointments.first;
    final dailySummary = DailySummaryCalculator.calculate(
      waterConsumedMl: totalWaterToday,
      waterGoalMl: settings.dailyWaterGoalMl,
      pendingVitamins:
          vitamins.length -
          vitaminLogs
              .where((log) => log.status.name != 'pending')
              .map((log) => log.vitaminId)
              .toSet()
              .length,
      pendingMedications: medications
          .where((medication) => medication.isPending)
          .length,
      registeredMeals: todayMeals.length,
      totalProteinGrams: totalProteinToday,
      proteinGoalGrams: proteinGoal,
      nextAppointment: nextAppointment == null
          ? null
          : DailySummaryItem(
              id: nextAppointment.id,
              title: nextAppointment.title,
              subtitle: nextAppointment.formattedDate,
              date: nextAppointment.date.value,
            ),
      latestExam: latestExam == null
          ? null
          : DailySummaryItem(
              id: latestExam.id,
              title: latestExam.formattedName,
              subtitle: latestExam.formattedDate,
              date: latestExam.examDate.value,
            ),
      weightProgress: weightProgress,
    );

    return MedicalReportSnapshot(
      generatedAt: now,
      template: template,
      profile: profile,
      weightHistory: List.unmodifiable(weightHistory),
      waterHistory: List.unmodifiable(waterHistory),
      vitamins: List.unmodifiable(vitamins),
      vitaminLogs: List.unmodifiable(vitaminLogs.cast()),
      medications: List.unmodifiable(medications),
      meals: List.unmodifiable(meals),
      appointments: List.unmodifiable(appointments),
      exams: List.unmodifiable(exams),
      dailySummary: dailySummary,
      attachments: attachments,
    );
  }

  bool _isSameDay(DateTime date, DateTime reference) {
    return date.year == reference.year &&
        date.month == reference.month &&
        date.day == reference.day;
  }
}

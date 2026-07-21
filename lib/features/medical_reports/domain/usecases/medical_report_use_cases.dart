import '../../../../core/health/health.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/services.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../meals/domain/usecases/use_cases.dart';
import '../../../medications/domain/usecases/use_cases.dart';
import '../../../medications/domain/entities/medication_log.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../medical_exams/domain/usecases/medical_exam_use_cases.dart';
import '../../../medical_prescriptions/domain/entities/entities.dart';
import '../../../medical_prescriptions/domain/usecases/use_cases.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../settings/domain/entities/entities.dart';
import '../../../settings/domain/usecases/use_cases.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../../../vitamins/domain/entities/vitamin_log.dart';
import '../../../water/domain/entities/entities.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../../../home/domain/models/models.dart';
import '../../../home/domain/usecases/use_cases.dart';
import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';

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
    required MedicalExamUseCases examUseCases,
    required SettingsUseCases settingsUseCases,
    required ClockService clock,
    HealthDashboardUseCases? dashboardUseCases,
    MedicalPrescriptionUseCases? prescriptionUseCases,
    required Future<TreatmentAdherenceQueryService> Function() treatment,
    Future<TodayDashboardReadModel> Function()? homeIntelligence,
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
       _clock = clock,
       _dashboardUseCases = dashboardUseCases,
       _prescriptionUseCases = prescriptionUseCases,
       _treatment = treatment,
       _homeIntelligence = homeIntelligence;

  final MedicalReportRepository _repository;
  final ProfileUseCases _profileUseCases;
  final WeightUseCases _weightUseCases;
  final WaterUseCases _waterUseCases;
  final VitaminUseCases _vitaminUseCases;
  final MedicationUseCases _medicationUseCases;
  final MealUseCases _mealUseCases;
  final AppointmentUseCases _appointmentUseCases;
  final MedicalExamUseCases _examUseCases;
  final SettingsUseCases _settingsUseCases;
  final ClockService _clock;
  final HealthDashboardUseCases? _dashboardUseCases;
  final MedicalPrescriptionUseCases? _prescriptionUseCases;
  final Future<TreatmentAdherenceQueryService> Function() _treatment;
  final Future<TodayDashboardReadModel> Function()? _homeIntelligence;

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
    final now = _clock.now();
    final periodStart = DateTime(now.year, now.month, now.day - 29);
    final periodEnd = DateTime(now.year, now.month, now.day);
    final dashboardFuture =
        _dashboardUseCases == null || _homeIntelligence != null
        ? Future<HealthDashboardAggregate?>.value(null)
        : _dashboardUseCases.load(start: periodStart, end: periodEnd);
    final results = await Future.wait<dynamic>([
      _profileUseCases.getProfile(),
      _weightUseCases.getHistory(),
      _waterUseCases.getHistory(),
      _vitaminUseCases.getAll(),
      _medicationUseCases.getAll(),
      _mealUseCases.getAll(),
      _appointmentUseCases.getAll(),
      _examUseCases.getHistory(),
      _settingsUseCases.getSettings(),
      _vitaminUseCases.getLogs(periodStart, periodEnd),
      _medicationUseCases.getLogs(periodStart, periodEnd),
      dashboardFuture,
      _prescriptionUseCases?.getAll() ??
          Future<List<MedicalPrescription>>.value(const []),
      _homeIntelligence == null
          ? Future<TodayDashboardReadModel?>.value(null)
          : _homeIntelligence(),
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
    final vitaminLogs = results[9] as List<VitaminLog>;
    final medicationLogs = results[10] as List<MedicationLog>;
    final dashboard = results[11] as HealthDashboardAggregate?;
    final prescriptions = results[12] as List<MedicalPrescription>;
    final homeIntelligence = results[13] as TodayDashboardReadModel?;
    final treatmentService = await _treatment();
    final treatmentAdherence = await treatmentService.summary(
      periodStart,
      periodEnd,
    );
    final treatmentToday = await treatmentService.today(periodEnd);
    final fallbackPendingVitamins = dashboard == null
        ? await _vitaminUseCases.getPendingCount(date: now)
        : null;
    final fallbackPendingMedications = dashboard == null
        ? await _medicationUseCases.getPendingCount(date: now)
        : null;
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
    final waterInPeriod = waterHistory
        .where((record) => !record.recordedAt.isBefore(periodStart))
        .toList();
    final averageDailyWaterMl = waterInPeriod.isEmpty
        ? 0
        : waterInPeriod.fold<int>(
                0,
                (total, record) => total + record.amount.valueInMl,
              ) ~/
              30;
    final todayMeals = meals.where((meal) => meal.wasRegisteredToday).toList();
    final mealsInPeriod = meals
        .where((meal) => !meal.mealDate.value.isBefore(periodStart))
        .toList();
    final totalProteinToday = todayMeals.fold<int>(
      0,
      (total, meal) => total + ((meal.proteinGrams as int?) ?? 0),
    );
    final averageDailyProteinGrams = mealsInPeriod.isEmpty
        ? 0
        : mealsInPeriod.fold<int>(
                0,
                (total, meal) => total + ((meal.proteinGrams as int?) ?? 0),
              ) ~/
              30;
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
    final typedExams = exams.cast<MedicalExam>();
    final latestExam = typedExams.isEmpty ? null : typedExams.first;
    final nextAppointment = upcomingAppointments.isEmpty
        ? null
        : upcomingAppointments.first;
    final calculatedSummary = DailySummaryCalculator.calculate(
      waterConsumedMl: totalWaterToday,
      waterGoalMl: settings.dailyWaterGoalMl,
      pendingVitamins: fallbackPendingVitamins ?? 0,
      pendingMedications: fallbackPendingMedications ?? 0,
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
              title: latestExam.title?.trim().isNotEmpty == true
                  ? latestExam.title!
                  : 'Exame laboratorial',
              subtitle: AppDateFormatter.short(latestExam.performedAt),
              date: latestExam.performedAt,
            ),
      weightProgress: weightProgress,
    );
    final dailySummary = dashboard == null && homeIntelligence == null
        ? calculatedSummary
        : DailySummary(
            hydration: calculatedSummary.hydration,
            pendingVitamins:
                dashboard?.today.pendingVitamins ??
                calculatedSummary.pendingVitamins,
            pendingMedications:
                dashboard?.today.pendingMedications ??
                calculatedSummary.pendingMedications,
            protein: calculatedSummary.protein,
            registeredMeals: todayMeals.length,
            healthScore:
                homeIntelligence?.healthScore ??
                dashboard?.today.healthScore ??
                calculatedSummary.healthScore,
            nextAppointment: calculatedSummary.nextAppointment,
            latestExam: calculatedSummary.latestExam,
            weightProgress: calculatedSummary.weightProgress,
          );
    double? categoryAdherence(RoutineCategory category) {
      final value = treatmentAdherence.byCategory[category];
      return value == null ||
              value.coverageState != AdherenceCoverageState.complete ||
              value.adherence == null
          ? null
          : value.adherence! * 100;
    }

    final vitaminAdherence = categoryAdherence(RoutineCategory.vitamin);
    final medicationAdherence = categoryAdherence(RoutineCategory.medication);
    final observations = _automaticObservations(
      settings: settings,
      averageDailyWaterMl: averageDailyWaterMl,
      averageDailyProteinGrams: averageDailyProteinGrams,
      proteinGoal: proteinGoal,
      vitaminAdherence: vitaminAdherence,
      medicationAdherence: medicationAdherence,
      upcomingAppointments: upcomingAppointments.length,
      hasRecentExams: typedExams.any(
        (exam) => !exam.performedAt.isBefore(periodStart),
      ),
    );

    return MedicalReportSnapshot(
      generatedAt: now,
      template: template,
      profile: profile,
      weightHistory: List.unmodifiable(weightHistory),
      waterHistory: List.unmodifiable(waterHistory),
      vitamins: List.unmodifiable(vitamins),
      vitaminLogs: List.unmodifiable(vitaminLogs),
      medications: List.unmodifiable(medications),
      medicationLogs: List.unmodifiable(medicationLogs),
      meals: List.unmodifiable(meals),
      appointments: List.unmodifiable(appointments),
      exams: List.unmodifiable(typedExams),
      prescriptions: List.unmodifiable(prescriptions),
      dailySummary: dailySummary,
      reportVersion: '1.0',
      periodStart: periodStart,
      averageDailyWaterMl: averageDailyWaterMl,
      mealsInPeriod: mealsInPeriod.length,
      averageDailyProteinGrams: averageDailyProteinGrams,
      vitaminAdherencePercent: vitaminAdherence,
      medicationAdherencePercent: medicationAdherence,
      automaticObservations: List.unmodifiable(observations),
      attachments: attachments,
      treatmentAdherence: treatmentAdherence,
      treatmentToday: treatmentToday,
      homeIntelligence: homeIntelligence,
    );
  }

  List<String> _automaticObservations({
    required AppSettings settings,
    required int averageDailyWaterMl,
    required int averageDailyProteinGrams,
    required int proteinGoal,
    required double? vitaminAdherence,
    required double? medicationAdherence,
    required int upcomingAppointments,
    required bool hasRecentExams,
  }) {
    final observations = <String>[];
    if (averageDailyWaterMl > 0 &&
        averageDailyWaterMl < settings.dailyWaterGoalMl) {
      observations.add(
        'A média diária de água no período ficou abaixo da meta configurada.',
      );
    }
    if (proteinGoal > 0 &&
        averageDailyProteinGrams > 0 &&
        averageDailyProteinGrams < proteinGoal) {
      observations.add(
        'A média de proteína registrada ficou abaixo da estimativa diária.',
      );
    }
    if (vitaminAdherence != null && vitaminAdherence < 80) {
      observations.add('A adesão registrada às vitaminas ficou abaixo de 80%.');
    }
    if (medicationAdherence != null && medicationAdherence < 80) {
      observations.add(
        'A adesão registrada aos medicamentos ficou abaixo de 80%.',
      );
    }
    if (upcomingAppointments == 0) {
      observations.add('Não há consulta futura registrada no aplicativo.');
    }
    if (!hasRecentExams) {
      observations.add('Não há exame registrado nos últimos 30 dias.');
    }
    return observations;
  }

  bool _isSameDay(DateTime date, DateTime reference) {
    return date.year == reference.year &&
        date.month == reference.month &&
        date.day == reference.day;
  }
}

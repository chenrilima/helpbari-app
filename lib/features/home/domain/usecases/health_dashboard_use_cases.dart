import '../../../../core/health/health.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../meals/domain/entities/entities.dart';
import '../../../meals/domain/usecases/use_cases.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../medical_exams/domain/usecases/medical_exam_use_cases.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../settings/domain/entities/entities.dart';
import '../../../settings/domain/usecases/use_cases.dart';
import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';
import '../../../water/domain/entities/entities.dart';
import '../../../water/domain/usecases/use_cases.dart';
import '../../../weight/domain/entities/entities.dart';
import '../../../weight/domain/usecases/use_cases.dart';
import '../models/models.dart';

class HealthDashboardUseCases {
  const HealthDashboardUseCases({
    required ProfileUseCases profile,
    required WeightUseCases weight,
    required WaterUseCases water,
    required MealUseCases meals,
    required AppointmentUseCases appointments,
    required MedicalExamUseCases exams,
    required SettingsUseCases settings,
    required Future<TreatmentAdherenceQueryService> Function() treatment,
  }) : _profile = profile,
       _weight = weight,
       _water = water,
       _meals = meals,
       _appointments = appointments,
       _exams = exams,
       _settings = settings,
       _treatment = treatment;

  final ProfileUseCases _profile;
  final WeightUseCases _weight;
  final WaterUseCases _water;
  final MealUseCases _meals;
  final AppointmentUseCases _appointments;
  final MedicalExamUseCases _exams;
  final SettingsUseCases _settings;
  final Future<TreatmentAdherenceQueryService> Function() _treatment;

  Future<HealthDashboardAggregate> load({
    required DateTime start,
    required DateTime end,
  }) async {
    final from = _day(start);
    final to = _day(end);
    final unavailable = <HealthDataSection>{};
    final results = await Future.wait<dynamic>([
      _read(
        () => _profile.getProfile(),
        HealthDataSection.profile,
        unavailable,
      ),
      _read(() => _weight.getHistory(), HealthDataSection.weight, unavailable),
      _read(() => _water.getHistory(), HealthDataSection.water, unavailable),
      _read(() => _meals.getAll(), HealthDataSection.meals, unavailable),
      _read(
        () => _appointments.getAll(),
        HealthDataSection.appointments,
        unavailable,
      ),
      _read(() => _exams.getHistory(), HealthDataSection.exams, unavailable),
      _read(
        () => _settings.getSettings(),
        HealthDataSection.settings,
        unavailable,
      ),
    ]);
    final profile = results[0] as Profile?;
    final weights = (results[1] as List<WeightRecord>?) ?? const [];
    final water = (results[2] as List<WaterRecord>?) ?? const [];
    final meals = (results[3] as List<Meal>?) ?? const [];
    final appointments = (results[4] as List<Appointment>?) ?? const [];
    final exams = (results[5] as List<MedicalExam>?) ?? const [];
    final settings = results[6] as AppSettings?;
    final treatment = await _treatment();
    final treatmentDays = await treatment.days(from, to);

    final days = <DailyHealthAggregate>[];
    for (
      var date = from;
      !date.isAfter(to);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      final dayWater = water.where((r) => _day(r.recordedAt) == date).toList();
      final dayMeals = meals
          .where((m) => _day(m.mealDate.value) == date)
          .toList();
      final dayWeights = weights
          .where((w) => _day(w.recordedAt.value) == date)
          .toList();
      final waterMl =
          unavailable.contains(HealthDataSection.water) || dayWater.isEmpty
          ? null
          : dayWater.fold<int>(0, (sum, r) => sum + r.amount.valueInMl);
      final protein =
          unavailable.contains(HealthDataSection.meals) || dayMeals.isEmpty
          ? null
          : dayMeals.fold<int>(0, (sum, m) => sum + (m.proteinGrams ?? 0));
      final weightKg = dayWeights.firstOrNull?.weight.value;
      final proteinGoal = profile == null
          ? null
          : ProteinCalculator.goalForWeightKg(
              weightKg ?? profile.initialWeight.value,
            );
      final treatmentToday = treatmentDays[_dateKey(date)]!;
      final treatmentAdherence =
          treatmentToday.adherence.coverageState ==
              AdherenceCoverageState.complete
          ? treatmentToday.adherence.adherence
          : null;
      final vitaminAdherence = treatmentAdherence;
      final medicationAdherence = treatmentAdherence;
      final pendingVitamins = treatmentToday.pendingFor(
        RoutineCategory.vitamin,
      );
      final pendingMedications = treatmentToday.pendingFor(
        RoutineCategory.medication,
      );
      final score = HealthScoreCalculator.calculateV2(
        HealthScoreInput(
          hydration:
              waterMl == null ||
                  settings == null ||
                  settings.dailyWaterGoalMl <= 0
              ? null
              : waterMl / settings.dailyWaterGoalMl,
          protein: protein == null || proteinGoal == null || proteinGoal <= 0
              ? null
              : protein / proteinGoal,
          meals: dayMeals.isEmpty ? null : dayMeals.length / 3,
          vitamins: vitaminAdherence,
          medications: medicationAdherence,
          weight: _weightProgress(profile, weightKg),
        ),
      );
      days.add(
        DailyHealthAggregate(
          date: date,
          waterMl: waterMl,
          waterGoalMl: settings?.dailyWaterGoalMl,
          mealsCount: dayMeals.isEmpty ? null : dayMeals.length,
          proteinGrams: protein,
          vitaminAdherence: vitaminAdherence,
          medicationAdherence: medicationAdherence,
          weightKg: weightKg,
          healthScore: score,
          pendingVitamins: pendingVitamins,
          pendingMedications: pendingMedications,
        ),
      );
    }
    final upcoming = appointments.where((a) => a.isUpcoming).toList()
      ..sort((a, b) => a.date.value.compareTo(b.date.value));
    return HealthDashboardAggregate(
      periodStart: from,
      periodEnd: to,
      days: List.unmodifiable(days),
      unavailableSections: Set.unmodifiable(unavailable),
      profile: profile,
      latestWeight: weights.firstOrNull,
      nextAppointment: upcoming.firstOrNull,
      latestExam: exams.firstOrNull,
    );
  }

  Future<T?> _read<T>(
    Future<T> Function() action,
    HealthDataSection section,
    Set<HealthDataSection> unavailable,
  ) async {
    try {
      return await action();
    } catch (_) {
      unavailable.add(section);
      return null;
    }
  }

  double? _weightProgress(Profile? profile, double? weight) {
    final target = profile?.targetWeight?.value;
    if (profile == null || target == null || weight == null) return null;
    return WeightProgressCalculator.calculate(
      initialWeightKg: profile.initialWeight.value,
      currentWeightKg: weight,
      targetWeightKg: target,
    ).progress;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

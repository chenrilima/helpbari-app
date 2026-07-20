import '../../../../core/health/health.dart';
import '../../../appointments/domain/entities/entities.dart';
import '../../../appointments/domain/usecases/use_cases.dart';
import '../../../meals/domain/entities/entities.dart';
import '../../../meals/domain/usecases/use_cases.dart';
import '../../../medications/domain/usecases/use_cases.dart';
import '../../../medical_exams/domain/entities/entities.dart';
import '../../../medical_exams/domain/usecases/medical_exam_use_cases.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/domain/usecases/use_cases.dart';
import '../../../settings/domain/entities/entities.dart';
import '../../../settings/domain/usecases/use_cases.dart';
import '../../../vitamins/domain/usecases/vitamin_use_cases.dart';
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
    required VitaminUseCases vitamins,
    required MedicationUseCases medications,
    required AppointmentUseCases appointments,
    required MedicalExamUseCases exams,
    required SettingsUseCases settings,
  }) : _profile = profile,
       _weight = weight,
       _water = water,
       _meals = meals,
       _vitamins = vitamins,
       _medications = medications,
       _appointments = appointments,
       _exams = exams,
       _settings = settings;

  final ProfileUseCases _profile;
  final WeightUseCases _weight;
  final WaterUseCases _water;
  final MealUseCases _meals;
  final VitaminUseCases _vitamins;
  final MedicationUseCases _medications;
  final AppointmentUseCases _appointments;
  final MedicalExamUseCases _exams;
  final SettingsUseCases _settings;

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
      _read(() => _vitamins.getAll(), HealthDataSection.vitamins, unavailable),
      _read(
        () => _medications.getAll(),
        HealthDataSection.medications,
        unavailable,
      ),
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
    final appointments = (results[6] as List<Appointment>?) ?? const [];
    final exams = (results[7] as List<MedicalExam>?) ?? const [];
    final settings = results[8] as AppSettings?;

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
      final vitaminAdherence = unavailable.contains(HealthDataSection.vitamins)
          ? null
          : await _vitamins.adherence(date, date) / 100;
      final medicationAdherence =
          unavailable.contains(HealthDataSection.medications)
          ? null
          : await _medications.adherence(date, date) / 100;
      final pendingVitamins = unavailable.contains(HealthDataSection.vitamins)
          ? null
          : await _vitamins.getPendingCount(date: date);
      final pendingMedications =
          unavailable.contains(HealthDataSection.medications)
          ? null
          : await _medications.getPendingCount(date: date);
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
}

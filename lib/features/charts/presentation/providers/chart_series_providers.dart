import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/health.dart';
import '../../../../core/services/service_providers.dart';
import '../../../meals/domain/entities/entities.dart';
import '../../../meals/presentation/providers/meal_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../profile/domain/entities/entities.dart';
import '../../../profile/presentation/providers/profile_use_case_providers.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../../water/domain/entities/entities.dart';
import '../../../water/presentation/providers/water_use_cases_provider.dart';
import '../../../weight/domain/entities/entities.dart';
import '../../../weight/presentation/providers/weight_use_cases_provider.dart';
import '../../domain/models/models.dart';

final weightChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final clock = ref.read(clockServiceProvider);
      final now = clock.now();
      final startDate = period.startDate(now);
      final records = await ref.read(weightUseCasesProvider).getHistory();

      final points =
          records
              .where(
                (record) =>
                    !_dateOnly(record.recordedAt.value).isBefore(startDate),
              )
              .toList()
            ..sort((a, b) => a.recordedAt.value.compareTo(b.recordedAt.value));

      return ChartSeries(
        title: 'Evolução do peso',
        type: ChartType.line,
        unit: 'kg',
        points: points
            .map(
              (record) => ChartPoint(
                date: record.recordedAt.value,
                value: record.weight.value,
              ),
            )
            .toList(),
        emptyTitle: 'Sem registros no período',
        emptyDescription: 'Registre seu peso para acompanhar a evolução.',
      );
    });

final waterChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final clock = ref.read(clockServiceProvider);
      final now = clock.now();
      final startDate = period.startDate(now);
      final records = await ref.read(waterUseCasesProvider).getHistory();
      final totals = _sumWaterByDay(records, startDate);

      return ChartSeries(
        title: 'Consumo de água',
        type: ChartType.bar,
        unit: 'ml',
        points: _filledDailyPoints(
          startDate: startDate,
          endDate: _dateOnly(now),
          valueForDate: (date) => (totals[date] ?? 0).toDouble(),
        ).where((point) => point.value > 0).toList(),
        emptyTitle: 'Sem consumo no período',
        emptyDescription: 'Registre água para visualizar seu consumo diário.',
      );
    });

final healthScoreChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final clock = ref.read(clockServiceProvider);
      final now = clock.now();
      final startDate = period.startDate(now);
      final profile = await ref.read(profileUseCasesProvider).getProfile();
      final settings = await ref.read(settingsUseCasesProvider).getSettings();
      final waterRecords = await ref.read(waterUseCasesProvider).getHistory();
      final meals = await ref.read(mealUseCasesProvider).getAll();
      final vitamins = await ref.read(vitaminUseCasesProvider).getAll();
      final vitaminLogs = await ref
          .read(vitaminUseCasesProvider)
          .getLogs(startDate, now);
      final medications = await ref.read(medicationUseCasesProvider).getAll();
      final weights = await ref.read(weightUseCasesProvider).getHistory();

      final waterByDay = _sumWaterByDay(waterRecords, startDate);
      final mealsByDay = _groupMealsByDay(meals, startDate);
      final weightProgress = _weightProgress(profile, weights);

      final points = _filledDailyPoints(
        startDate: startDate,
        endDate: _dateOnly(now),
        valueForDate: (date) {
          final dayMeals = mealsByDay[date] ?? const <Meal>[];
          final proteinTotal = dayMeals.fold<int>(
            0,
            (total, meal) => total + (meal.proteinGrams ?? 0),
          );
          final proteinGoal = profile == null
              ? 0
              : ProteinCalculator.goalForWeightKg(
                  weights.firstOrNull?.weight.value ??
                      profile.initialWeight.value,
                );
          final hydration = HydrationCalculator.calculate(
            currentMl: waterByDay[date] ?? 0,
            goalMl: settings.dailyWaterGoalMl,
          );
          final protein = ProteinCalculator.calculate(
            currentGrams: proteinTotal,
            goalGrams: proteinGoal,
          );

          return HealthScoreCalculator.calculate(
            hydration: hydration,
            protein: protein,
            pendingVitamins:
                vitamins.length -
                vitaminLogs
                    .where(
                      (log) =>
                          _dateOnly(log.date) == date &&
                          log.status.name != 'pending',
                    )
                    .map((log) => log.vitaminId)
                    .toSet()
                    .length,
            pendingMedications: medications
                .where((item) => item.isPending)
                .length,
            registeredMeals: dayMeals.length,
            weightProgress: weightProgress,
          ).score.toDouble();
        },
      ).where((point) => point.value > 0).toList();

      return ChartSeries(
        title: 'Health Score',
        type: ChartType.line,
        unit: '%',
        points: points,
        emptyTitle: 'Sem score no período',
        emptyDescription:
            'Registre água, refeições e rotina para formar o Health Score.',
      );
    });

final vitaminAdherenceChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final useCases = ref.read(vitaminUseCasesProvider);
      final now = ref.read(clockServiceProvider).now();
      final start = period.startDate(now);
      final vitamins = await useCases.getAll();
      final adherence = vitamins.isEmpty
          ? null
          : await useCases.adherence(start, now);

      return ChartSeries(
        title: 'Aderência de vitaminas',
        type: ChartType.bar,
        unit: '%',
        points: adherence == null
            ? const []
            : [ChartPoint(date: now, value: adherence, label: 'Hoje')],
        emptyTitle: 'Sem vitaminas cadastradas',
        emptyDescription:
            'Cadastre vitaminas e marque como tomadas para acompanhar a aderência.',
      );
    });

final medicationAdherenceChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final medications = await ref.read(medicationUseCasesProvider).getAll();
      final adherence = medications.isEmpty
          ? null
          : medications.where((item) => item.isTaken).length /
                medications.length *
                100;

      return ChartSeries(
        title: 'Aderência de medicamentos',
        type: ChartType.bar,
        unit: '%',
        points: adherence == null
            ? const []
            : [
                ChartPoint(
                  date: ref.read(clockServiceProvider).now(),
                  value: adherence,
                  label: 'Hoje',
                ),
              ],
        emptyTitle: 'Sem medicamentos cadastrados',
        emptyDescription:
            'Cadastre medicamentos e marque como tomados para acompanhar a aderência.',
      );
    });

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Map<DateTime, int> _sumWaterByDay(
  List<WaterRecord> records,
  DateTime startDate,
) {
  final totals = <DateTime, int>{};

  for (final record in records) {
    final date = _dateOnly(record.recordedAt);
    if (date.isBefore(startDate)) continue;

    totals[date] = (totals[date] ?? 0) + record.amount.valueInMl;
  }

  return totals;
}

Map<DateTime, List<Meal>> _groupMealsByDay(
  List<Meal> meals,
  DateTime startDate,
) {
  final groups = <DateTime, List<Meal>>{};

  for (final meal in meals) {
    final date = _dateOnly(meal.mealDate.value);
    if (date.isBefore(startDate)) continue;

    groups.putIfAbsent(date, () => []).add(meal);
  }

  return groups;
}

List<ChartPoint> _filledDailyPoints({
  required DateTime startDate,
  required DateTime endDate,
  required double Function(DateTime date) valueForDate,
}) {
  final points = <ChartPoint>[];
  var date = startDate;

  while (!date.isAfter(endDate)) {
    points.add(ChartPoint(date: date, value: valueForDate(date)));
    date = date.add(const Duration(days: 1));
  }

  return points;
}

WeightProgressResult? _weightProgress(
  Profile? profile,
  List<WeightRecord> weights,
) {
  final latestWeight = weights.firstOrNull;
  final targetWeight = profile?.targetWeight;

  if (profile == null || latestWeight == null || targetWeight == null) {
    return null;
  }

  return WeightProgressCalculator.calculate(
    initialWeightKg: profile.initialWeight.value,
    currentWeightKg: latestWeight.weight.value,
    targetWeightKg: targetWeight.value,
  );
}

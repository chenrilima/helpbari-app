import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/models/models.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../../core/services/service_providers.dart';
import '../../domain/models/models.dart';

final healthPeriodAggregateProvider = FutureProvider.autoDispose
    .family<HealthDashboardAggregate, ChartPeriod>((ref, period) {
      final now = ref.read(clockServiceProvider).now();
      return ref
          .watch(healthDashboardUseCasesProvider)
          .load(start: period.startDate(now), end: now);
    });

final weightChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      _require(data, HealthDataSection.weight, 'peso');
      return ChartSeries(
        title: 'Evolução do peso',
        type: ChartType.line,
        unit: 'kg',
        points: data.days
            .where((day) => day.weightKg != null)
            .map((day) => ChartPoint(date: day.date, value: day.weightKg!))
            .toList(),
        emptyTitle: 'Sem registros no período',
        emptyDescription: 'Registre seu peso para acompanhar a evolução.',
      );
    });

final waterChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      _require(data, HealthDataSection.water, 'água');
      _require(data, HealthDataSection.settings, 'meta de água');
      return ChartSeries(
        title: 'Consumo de água',
        type: ChartType.bar,
        unit: 'ml',
        referenceValue: data.today.waterGoalMl?.toDouble(),
        referenceLabel: 'Meta vigente',
        points: data.days
            .where((day) => day.waterMl != null)
            .map(
              (day) =>
                  ChartPoint(date: day.date, value: day.waterMl!.toDouble()),
            )
            .toList(),
        emptyTitle: 'Sem consumo no período',
        emptyDescription: 'Registre água para visualizar seu consumo diário.',
      );
    });

final mealProteinChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      _require(data, HealthDataSection.meals, 'refeições');
      return ChartSeries(
        title: 'Proteína por dia',
        type: ChartType.bar,
        unit: 'g',
        points: data.days
            .where((day) => day.proteinGrams != null)
            .map(
              (day) => ChartPoint(
                date: day.date,
                value: day.proteinGrams!.toDouble(),
                label: '${day.mealsCount} refeições',
              ),
            )
            .toList(),
        emptyTitle: 'Sem refeições no período',
        emptyDescription:
            'Registre refeições e proteína para acompanhar por dia.',
      );
    });

final healthScoreChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      return ChartSeries(
        title: 'Health Score',
        type: ChartType.line,
        unit: '%',
        points: data.days
            .where((day) => day.healthScore.hasData)
            .map(
              (day) => ChartPoint(
                date: day.date,
                value: day.healthScore.score.toDouble(),
                label: day.healthScore.compositionExplanation,
              ),
            )
            .toList(),
        emptyTitle: 'Sem score no período',
        emptyDescription: 'Registre sua rotina para formar o indicador diário.',
      );
    });

final vitaminAdherenceChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      _require(data, HealthDataSection.vitamins, 'vitaminas');
      return _adherenceSeries(
        title: 'Aderência de vitaminas',
        days: data.days,
        value: (day) => day.vitaminAdherence,
      );
    });

final medicationAdherenceChartSeriesProvider = FutureProvider.autoDispose
    .family<ChartSeries, ChartPeriod>((ref, period) async {
      final data = await ref.watch(
        healthPeriodAggregateProvider(period).future,
      );
      _require(data, HealthDataSection.medications, 'medicamentos');
      return _adherenceSeries(
        title: 'Aderência de medicamentos',
        days: data.days,
        value: (day) => day.medicationAdherence,
      );
    });

ChartSeries _adherenceSeries({
  required String title,
  required List<DailyHealthAggregate> days,
  required double? Function(DailyHealthAggregate) value,
}) => ChartSeries(
  title: title,
  type: ChartType.bar,
  unit: '%',
  points: days
      .where((day) => value(day) != null)
      .map((day) => ChartPoint(date: day.date, value: value(day)! * 100))
      .toList(),
  emptyTitle: 'Sem registros de adesão no período',
  emptyDescription: 'Registre tomado, ignorado ou pendente para acompanhar.',
);

void _require(
  HealthDashboardAggregate data,
  HealthDataSection section,
  String label,
) {
  if (!data.isAvailable(section)) {
    throw StateError('Dados de $label indisponíveis temporariamente.');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import '../providers/chart_series_providers.dart';
import 'hb_async_chart_card.dart';

class MealProteinChartWidget extends ConsumerStatefulWidget {
  const MealProteinChartWidget({super.key});

  @override
  ConsumerState<MealProteinChartWidget> createState() =>
      _MealProteinChartWidgetState();
}

class _MealProteinChartWidgetState
    extends ConsumerState<MealProteinChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final provider = mealProteinChartSeriesProvider(_period);
    return HBAsyncChartCard(
      title: 'Refeições e proteína',
      subtitle: 'Proteína registrada por dia; detalhes indicam as refeições',
      period: _period,
      onPeriodChanged: (value) => setState(() => _period = value),
      series: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      color: AppColors.secondary,
      emptyIcon: Icons.restaurant_outlined,
    );
  }
}

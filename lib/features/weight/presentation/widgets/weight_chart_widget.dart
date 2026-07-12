import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../charts/charts.dart';

class WeightChartWidget extends ConsumerStatefulWidget {
  const WeightChartWidget({super.key});

  @override
  ConsumerState<WeightChartWidget> createState() => _WeightChartWidgetState();
}

class _WeightChartWidgetState extends ConsumerState<WeightChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(weightChartSeriesProvider(_period));

    return HBAsyncChartCard(
      title: 'Evolução do peso',
      subtitle: 'Registros do período selecionado',
      period: _period,
      onPeriodChanged: (value) {
        setState(() => _period = value);
      },
      series: series,
      onRetry: () => ref.invalidate(weightChartSeriesProvider(_period)),
      color: AppColors.primary,
      emptyIcon: AppIcons.weight,
    );
  }
}

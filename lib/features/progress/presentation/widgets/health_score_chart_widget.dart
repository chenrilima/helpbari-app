import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../charts/charts.dart';

class HealthScoreChartWidget extends ConsumerStatefulWidget {
  const HealthScoreChartWidget({super.key});

  @override
  ConsumerState<HealthScoreChartWidget> createState() =>
      _HealthScoreChartWidgetState();
}

class _HealthScoreChartWidgetState
    extends ConsumerState<HealthScoreChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(healthScoreChartSeriesProvider(_period));

    return HBAsyncChartCard(
      title: 'Health Score',
      subtitle: 'Pontuação calculada a partir dos registros',
      period: _period,
      onPeriodChanged: (value) {
        setState(() => _period = value);
      },
      series: series,
      color: AppColors.success,
      emptyIcon: Icons.monitor_heart_outlined,
    );
  }
}

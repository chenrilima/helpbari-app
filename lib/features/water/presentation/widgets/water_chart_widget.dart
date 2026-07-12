import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../charts/charts.dart';

class WaterChartWidget extends ConsumerStatefulWidget {
  const WaterChartWidget({super.key});

  @override
  ConsumerState<WaterChartWidget> createState() => _WaterChartWidgetState();
}

class _WaterChartWidgetState extends ConsumerState<WaterChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(waterChartSeriesProvider(_period));

    return HBAsyncChartCard(
      title: 'Consumo de água',
      subtitle: 'Total diário versus a meta vigente atual',
      period: _period,
      onPeriodChanged: (value) {
        setState(() => _period = value);
      },
      series: series,
      onRetry: () => ref.invalidate(waterChartSeriesProvider(_period)),
      color: AppColors.info,
      emptyIcon: AppIcons.water,
    );
  }
}

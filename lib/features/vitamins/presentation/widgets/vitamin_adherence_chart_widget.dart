import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../charts/charts.dart';

class VitaminAdherenceChartWidget extends ConsumerStatefulWidget {
  const VitaminAdherenceChartWidget({super.key});

  @override
  ConsumerState<VitaminAdherenceChartWidget> createState() =>
      _VitaminAdherenceChartWidgetState();
}

class _VitaminAdherenceChartWidgetState
    extends ConsumerState<VitaminAdherenceChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(vitaminAdherenceChartSeriesProvider(_period));

    return HBAsyncChartCard(
      title: 'Aderência de vitaminas',
      subtitle: 'Percentual de vitaminas marcadas como tomadas',
      period: _period,
      onPeriodChanged: (value) {
        setState(() => _period = value);
      },
      series: series,
      onRetry: () =>
          ref.invalidate(vitaminAdherenceChartSeriesProvider(_period)),
      color: AppColors.warning,
      emptyIcon: AppIcons.vitamin,
    );
  }
}

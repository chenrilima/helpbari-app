import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../charts/charts.dart';

class MedicationAdherenceChartWidget extends ConsumerStatefulWidget {
  const MedicationAdherenceChartWidget({super.key});

  @override
  ConsumerState<MedicationAdherenceChartWidget> createState() =>
      _MedicationAdherenceChartWidgetState();
}

class _MedicationAdherenceChartWidgetState
    extends ConsumerState<MedicationAdherenceChartWidget> {
  ChartPeriod _period = ChartPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(medicationAdherenceChartSeriesProvider(_period));

    return HBAsyncChartCard(
      title: 'Aderência de medicamentos',
      subtitle: 'Percentual de medicamentos marcados como tomados',
      period: _period,
      onPeriodChanged: (value) {
        setState(() => _period = value);
      },
      series: series,
      onRetry: () =>
          ref.invalidate(medicationAdherenceChartSeriesProvider(_period)),
      color: AppColors.secondary,
      emptyIcon: Icons.medication_outlined,
    );
  }
}

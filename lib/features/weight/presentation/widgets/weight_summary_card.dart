import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({required this.record, super.key});

  final WeightRecord record;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: 'Último peso',
      value: record.formattedWeight,
      icon: Icons.monitor_weight_outlined,
    );
  }
}

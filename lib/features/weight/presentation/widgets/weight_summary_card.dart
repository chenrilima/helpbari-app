import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({required this.record, this.onTap, super.key});

  final WeightRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = HBMetricCard(
      title: 'Último peso',
      value: record.formattedWeight,
      icon: Icons.monitor_weight_outlined,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: card,
    );
  }
}

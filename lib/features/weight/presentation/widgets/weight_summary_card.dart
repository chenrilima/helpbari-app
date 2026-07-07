import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({
    required this.record,
    this.description,
    this.onTap,
    super.key,
  });

  final WeightRecord record;
  final String? description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: 'Último peso',
      value: record.formattedWeight,
      description: description,
      icon: AppIcons.weight,
      onTap: onTap,
    );
  }
}

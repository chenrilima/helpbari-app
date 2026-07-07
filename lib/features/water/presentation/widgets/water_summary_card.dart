import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class WaterSummaryCard extends StatelessWidget {
  const WaterSummaryCard({required this.totalToday, super.key});

  final String totalToday;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: 'Consumo de hoje',
      value: totalToday,
      icon: AppIcons.water,
    );
  }
}

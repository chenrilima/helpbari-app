import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class MealSummaryCard extends StatelessWidget {
  const MealSummaryCard({
    required this.todayCount,
    required this.totalProteinToday,
    super.key,
  });

  final int todayCount;
  final int totalProteinToday;

  @override
  Widget build(BuildContext context) {
    final value = todayCount == 0
        ? 'Nenhuma hoje'
        : todayCount == 1
        ? '1 refeição'
        : '$todayCount refeições';

    final description = totalProteinToday <= 0
        ? 'Proteína não informada'
        : '$totalProteinToday g de proteína hoje';

    return HBMetricCard(
      title: 'Refeições',
      value: value,
      description: description,
      icon: Icons.restaurant_outlined,
    );
  }
}

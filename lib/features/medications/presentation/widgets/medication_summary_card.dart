import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class MedicationSummaryCard extends StatelessWidget {
  const MedicationSummaryCard({required this.pendingCount, super.key});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final value = pendingCount == 0
        ? 'Tudo em dia'
        : '$pendingCount pendente${pendingCount > 1 ? 's' : ''}';

    return HBMetricCard(
      title: 'Medicamentos',
      value: value,
      description: 'Acompanhe sua rotina de remédios.',
      icon: Icons.medication_outlined,
    );
  }
}

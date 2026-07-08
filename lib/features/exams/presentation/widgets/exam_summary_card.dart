import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ExamSummaryCard extends StatelessWidget {
  const ExamSummaryCard({required this.exam, super.key});

  final Exam exam;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: 'Último exame',
      value: exam.formattedName,
      description: exam.formattedDate,
      icon: AppIcons.health,
    );
  }
}

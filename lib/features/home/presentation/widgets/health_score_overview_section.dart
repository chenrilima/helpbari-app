import 'package:flutter/material.dart';

import '../../../../core/health/health.dart';
import '../../../../design_system/design_system.dart';
import 'home_section.dart';

class HealthScoreOverviewSection extends StatelessWidget {
  const HealthScoreOverviewSection({required this.healthScore, super.key});

  final HealthScoreResult healthScore;

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Resumo de hoje',
      subtitle: 'Pontuação baseada na sua rotina diária.',
      child: HBMetricCard(
        title: healthScore.label,
        value: '${healthScore.score}%',
        description: healthScore.message,
        icon: Icons.favorite_outline,
      ),
    );
  }
}

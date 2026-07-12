import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ReportTemplateCard extends StatelessWidget {
  const ReportTemplateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText(
            'Template completo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const HBGap.sm(),
          HBText(
            'Paciente, peso, água, vitaminas, medicamentos, alimentação, consultas, exames, Health Score, evolução e gráficos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const HBGap.md(),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _TemplatePill('PDF'),
              _TemplatePill('Gráficos'),
              _TemplatePill('Referências de exames'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplatePill extends StatelessWidget {
  const _TemplatePill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: HBText(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

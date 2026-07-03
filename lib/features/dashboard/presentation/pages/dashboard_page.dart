import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/hb_card.dart';
import '../../../../shared/widgets/hb_responsive_page.dart';
import '../../../../shared/widgets/hb_section_header.dart';
import '../widgets/dashboard_metric_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HBResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('HelpBari', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Seu companheiro na jornada bariátrica.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            const HBCard(
              backgroundColor: AppColors.primaryLight,
              child: _WelcomeContent(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const HBSectionHeader(
              title: 'Resumo de hoje',
              subtitle: 'Acompanhe os principais pontos da sua rotina.',
            ),
            const SizedBox(height: AppSpacing.md),
            const DashboardMetricCard(
              title: 'Peso atual',
              value: 'Ainda não informado',
              description:
                  'Cadastre seu primeiro peso para iniciar o histórico.',
              icon: Icons.monitor_weight_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            const DashboardMetricCard(
              title: 'Água hoje',
              value: '0 ml',
              description: 'Sua meta diária aparecerá aqui.',
              icon: Icons.water_drop_outlined,
              iconBackgroundColor: AppColors.secondaryLight,
              iconColor: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const DashboardMetricCard(
              title: 'Vitaminas',
              value: 'Nenhuma cadastrada',
              description: 'Configure lembretes para sua rotina diária.',
              icon: Icons.medication_liquid_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fundação criada', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Agora temos tema, tokens visuais, responsividade, cards reutilizáveis e estrutura inicial por features.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

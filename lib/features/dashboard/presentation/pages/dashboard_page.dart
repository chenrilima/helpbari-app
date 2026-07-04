import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

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
            const HBSection(
              title: 'Resumo de hoje',
              subtitle: 'Acompanhe os principais pontos da sua rotina.',
              child: Column(
                children: [
                  HBMetricCard(
                    title: 'Peso atual',
                    value: 'Ainda não informado',
                    description:
                        'Cadastre seu primeiro peso para iniciar o histórico.',
                    icon: AppIcons.weight,
                  ),
                  SizedBox(height: AppSpacing.md),
                  HBMetricCard(
                    title: 'Água hoje',
                    value: '0 ml',
                    description: 'Sua meta diária aparecerá aqui.',
                    icon: AppIcons.water,
                    iconBackgroundColor: AppColors.secondaryLight,
                    iconColor: AppColors.secondary,
                  ),
                  SizedBox(height: AppSpacing.md),
                  HBMetricCard(
                    title: 'Vitaminas',
                    value: 'Nenhuma cadastrada',
                    description: 'Configure lembretes para sua rotina diária.',
                    icon: AppIcons.vitamin,
                  ),
                ],
              ),
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

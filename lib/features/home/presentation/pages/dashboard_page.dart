import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HBPage(
      header: _DashboardHeader(),
      children: [
        HBCard(
          backgroundColor: AppColors.primaryLight,
          child: _WelcomeContent(),
        ),
        HBGap.xl(),
        HBSection(
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
              HBGap.md(),
              HBMetricCard(
                title: 'Água hoje',
                value: '0 ml',
                description: 'Sua meta diária aparecerá aqui.',
                icon: AppIcons.water,
                iconBackgroundColor: AppColors.secondaryLight,
                iconColor: AppColors.secondary,
              ),
              HBGap.md(),
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
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText('HelpBari', style: Theme.of(context).textTheme.headlineLarge),
        const HBGap.sm(),
        HBText(
          'Seu companheiro na jornada bariátrica.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
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
        HBText(
          'Fundação criada',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const HBGap.sm(),
        HBText(
          'Agora temos tema, tokens visuais, responsividade, cards reutilizáveis e estrutura inicial por features.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

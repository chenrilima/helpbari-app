import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../design_system/design_system.dart';

class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBScaffold(
      appBar: const HBAppBar(
        title: 'Design System',
        subtitle: 'Componentes base do HelpBari',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBSection(
            title: 'Botões',
            subtitle: 'Estados principais dos botões.',
            child: Column(
              children: [
                HBButton(label: 'Botão principal', onPressed: () {}),
                const HBGap.md(),
                HBButton(
                  label: 'Carregando',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const HBGap.xl(),
          HBSection(
            title: 'Cards',
            subtitle: 'Container padrão para agrupamento de conteúdo.',
            child: Column(
              children: [
                const HBCard(
                  child: HBText('Este é um card padrão do HelpBari.'),
                ),
                const HBGap.lg(),
                HBMetricCard(
                  title: 'Peso atual',
                  value: AppWeightFormatter.kg(94.8),
                  description: 'Atualizado hoje',
                  icon: AppIcons.weight,
                ),
                const HBGap.md(),
                HBMetricCard(
                  title: 'Água hoje',
                  value: AppWaterFormatter.ml(1200),
                  description: AppWaterFormatter.dailyGoal(2000),
                  icon: AppIcons.water,
                  iconBackgroundColor: AppColors.secondaryLight,
                  iconColor: AppColors.secondary,
                ),
              ],
            ),
          ),

          const HBGap.xl(),
          const HBSection(
            title: 'Feedback',
            subtitle: 'Estados de carregamento e vazio.',
            child: HBEmptyState(
              title: 'Nenhum registro encontrado',
              description:
                  'Quando uma feature ainda não tiver dados, usamos este componente.',
              icon: AppIcons.empty,
            ),
          ),
          const HBGap.xl(),
          const HBSection(
            title: 'Loading',
            child: HBLoading(message: 'Carregando informações...'),
          ),
        ],
      ),
    );
  }
}

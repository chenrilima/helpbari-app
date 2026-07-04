import 'package:flutter/material.dart';

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
                const SizedBox(height: AppSpacing.md),
                HBButton(
                  label: 'Carregando',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const HBSection(
            title: 'Cards',
            subtitle: 'Container padrão para agrupamento de conteúdo.',
            child: HBCard(child: Text('Este é um card padrão do HelpBari.')),
          ),
          const SizedBox(height: AppSpacing.xl),
          const HBSection(
            title: 'Feedback',
            subtitle: 'Estados de carregamento e vazio.',
            child: HBEmptyState(
              title: 'Nenhum registro encontrado',
              description:
                  'Quando uma feature ainda não tiver dados, usamos este componente.',
              icon: Icons.inbox_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const HBSection(
            title: 'Loading',
            child: HBLoading(message: 'Carregando informações...'),
          ),
        ],
      ),
    );
  }
}

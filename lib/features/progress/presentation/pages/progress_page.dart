import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/progress_view_model_provider.dart';
import '../widgets/health_score_chart_widget.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadProgress);
  }

  Future<void> _loadProgress() async {
    await ref.read(progressViewModelProvider.notifier).loadProgress();
  }

  Future<void> _openCompleteProfile() async {
    await context.pushAndRefresh(
      AppRoutes.completeProfile,
      onRefresh: _loadProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressViewModelProvider);

    if (state.isLoading) {
      return const HBPage(
        appBar: HBAppBar(title: 'Evolução'),
        children: [HBLoading(message: 'Carregando sua evolução...')],
      );
    }

    final summary = state.summary;

    if (summary == null) {
      return HBPage(
        appBar: const HBAppBar(title: 'Evolução'),
        children: [
          HBEmptyState(
            title: 'Complete seu perfil',
            description: 'Precisamos do seu perfil para calcular sua evolução.',
            icon: AppIcons.profile,
            actionLabel: 'Completar perfil',
            onActionPressed: _openCompleteProfile,
          ),
        ],
      );
    }

    return HBPage(
      appBar: const HBAppBar(
        title: 'Evolução',
        subtitle: 'Indicadores da sua jornada',
      ),
      children: [
        _ProgressSection(
          title: 'Peso',
          summary:
              '${summary.formattedCurrentWeight} • ${summary.formattedWeightLost}',
          icon: AppIcons.weight,
          route: AppRoutes.weight,
        ),
        const HBGap.md(),
        const _ProgressSection(
          title: 'Água',
          summary: 'Acompanhe seus registros e sua meta de hidratação.',
          icon: Icons.water_drop_outlined,
          route: AppRoutes.water,
        ),
        const HBGap.md(),
        const _ProgressSection(
          title: 'Alimentação',
          summary: 'Consulte refeições e proteína registradas.',
          icon: Icons.restaurant_outlined,
          route: AppRoutes.meals,
        ),
        const HBGap.md(),
        const _ProgressSection(
          title: 'Tratamento',
          summary: 'Veja o acompanhamento e o histórico do tratamento.',
          icon: Icons.medication_outlined,
          route: AppRoutes.treatment,
        ),
        const HBGap.xl(),
        const HealthScoreChartWidget(),
        const HBGap.sm(),
        const HBCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline),
            title: HBText('Como o Health Score é composto'),
            subtitle: HBText(
              'O indicador usa somente componentes com dados disponíveis. A cobertura mostra quanto do período pôde ser avaliado. É um indicador de acompanhamento, não uma avaliação médica.',
            ),
          ),
        ),
        const HBGap.md(),
        const _ProgressSection(
          title: 'Bioimpedância',
          summary: 'Acompanhe suas medições corporais ao longo do tempo.',
          icon: Icons.monitor_weight_outlined,
          route: AppRoutes.bioimpedance,
        ),
        const HBGap.md(),
        const _ProgressSection(
          title: 'Relatórios',
          summary: 'Gere e consulte relatórios a partir dos dados autorizados.',
          icon: Icons.description_outlined,
          route: AppRoutes.medicalReports,
        ),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.title,
    required this.summary,
    required this.icon,
    required this.route,
  });

  final String title;
  final String summary;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) => HBCard(
    onTap: () => context.push(route),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: HBText(title),
      subtitle: HBText(summary),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

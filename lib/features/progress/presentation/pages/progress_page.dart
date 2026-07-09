import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/progress_view_model_provider.dart';
import '../widgets/health_score_chart_widget.dart';
import '../widgets/progress_metric_card.dart';

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
        ProgressMetricCard(
          title: 'Peso atual',
          value: summary.formattedCurrentWeight,
          description: summary.formattedWeightLost,
          icon: AppIcons.weight,
        ),
        const HBGap.md(),
        ProgressMetricCard(
          title: 'Peso inicial',
          value: summary.formattedInitialWeight,
          icon: AppIcons.weight,
        ),
        const HBGap.md(),
        ProgressMetricCard(
          title: 'Meta',
          value: summary.formattedTargetProgress,
          description: summary.formattedRemainingToTarget,
          icon: Icons.flag_outlined,
        ),
        const HBGap.md(),
        ProgressMetricCard(
          title: 'IMC inicial',
          value: summary.formattedInitialBmi,
          icon: Icons.monitor_heart_outlined,
        ),
        const HBGap.md(),
        ProgressMetricCard(
          title: 'Dias desde a cirurgia',
          value: '${summary.profile.daysSinceSurgery} dias',
          icon: Icons.calendar_month_outlined,
        ),
        const HBGap.xl(),
        const HealthScoreChartWidget(),
      ],
    );
  }
}

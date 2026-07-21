import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/home_intelligence_models.dart';
import 'home_section.dart';
import 'quick_action_card.dart';
import 'today_task_card.dart';

class NextActionsSection extends StatelessWidget {
  const NextActionsSection({
    required this.model,
    required this.onAction,
    super.key,
  });

  final NextActionsReadModel model;
  final ValueChanged<NextActionReadModel> onAction;

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: 'Agora',
      subtitle: 'O que merece atenção neste momento.',
      child: model.actions.isEmpty
          ? const HBEmptyState(
              title: 'Tudo acompanhado por agora',
              description:
                  'Sua próxima ação aparecerá aqui quando for aplicável.',
              icon: Icons.check_circle_outline,
            )
          : Column(
              children: [
                for (var index = 0; index < model.actions.length; index++) ...[
                  TodayTaskCard(
                    icon: _icon(model.actions[index].priority),
                    title: model.actions[index].title,
                    subtitle: model.actions[index].reason,
                    onTap: () => onAction(model.actions[index]),
                  ),
                  if (index != model.actions.length - 1) const HBGap.sm(),
                ],
              ],
            ),
    );
  }

  IconData _icon(HomeActionPriority priority) => switch (priority) {
    HomeActionPriority.critical => Icons.priority_high_rounded,
    HomeActionPriority.high => Icons.schedule_rounded,
    HomeActionPriority.medium => Icons.event_note_rounded,
    HomeActionPriority.low => Icons.checklist_rounded,
  };
}

class IntelligentAgendaSection extends StatelessWidget {
  const IntelligentAgendaSection({
    required this.model,
    required this.todayOnly,
    required this.onItem,
    super.key,
  });

  final AgendaReadModel model;
  final bool todayOnly;
  final ValueChanged<AgendaItemReadModel> onItem;

  @override
  Widget build(BuildContext context) {
    final today = model.start;
    final items = model.items
        .where((item) {
          if (!todayOnly) return true;
          return item.effectiveAt.year == today.year &&
              item.effectiveAt.month == today.month &&
              item.effectiveAt.day == today.day;
        })
        .take(todayOnly ? 5 : 3)
        .toList(growable: false);
    return HomeSection(
      title: todayOnly ? 'Agenda de hoje' : 'Próximos compromissos',
      child: items.isEmpty
          ? HBEmptyState(
              title: 'Nenhum item aplicável',
              description: todayOnly
                  ? 'Não há ocorrências ou consultas para hoje.'
                  : 'Não há compromissos nos próximos sete dias.',
              icon: Icons.event_available_outlined,
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Opacity(
                    opacity: items[index].state == AgendaItemState.resolved
                        ? .62
                        : 1,
                    child: TodayTaskCard(
                      icon: _icon(items[index]),
                      title: items[index].title,
                      subtitle: _subtitle(items[index]),
                      onTap: () => onItem(items[index]),
                    ),
                  ),
                  if (index != items.length - 1) const HBGap.sm(),
                ],
              ],
            ),
    );
  }

  IconData _icon(AgendaItemReadModel item) => switch (item.type) {
    AgendaItemType.treatment => Icons.medication_outlined,
    AgendaItemType.appointment => Icons.calendar_month_outlined,
    AgendaItemType.importantEvent => Icons.event_note_outlined,
  };

  String _subtitle(AgendaItemReadModel item) {
    final hour = item.effectiveAt.hour.toString().padLeft(2, '0');
    final minute = item.effectiveAt.minute.toString().padLeft(2, '0');
    final state = switch (item.state) {
      AgendaItemState.now => 'janela aberta',
      AgendaItemState.next => 'próximo',
      AgendaItemState.future => 'futuro',
      AgendaItemState.resolved => 'resolvido',
      AgendaItemState.missed => 'sem registro',
      AgendaItemState.canceled => 'cancelado',
      AgendaItemState.requiresReview => 'requer revisão',
      AgendaItemState.unavailable => 'indisponível',
    };
    return '$hour:$minute • $state';
  }
}

class DailyProgressSection extends StatelessWidget {
  const DailyProgressSection({required this.model, super.key});

  final ProgressSummaryReadModel model;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      model.routine,
      model.water,
      model.protein,
      model.weight,
      model.streak,
    ];
    return HomeSection(
      title: 'Progresso do dia',
      subtitle: 'Cada indicador usa sua própria cobertura de dados.',
      child: Column(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            _ProgressCard(metric: metrics[index]),
            if (index != metrics.length - 1) const HBGap.sm(),
          ],
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.metric});
  final ProgressMetricReadModel metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          metric.accessibilityLabel ?? '${metric.label}, dados insuficientes',
      child: HBCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: HBText(
                    metric.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                HBText(_value(metric)),
              ],
            ),
            const HBGap.sm(),
            if (metric.progress != null)
              LinearProgressIndicator(value: metric.progress)
            else
              HBText(
                metric.coverage.reason ?? 'Aguardando dados suficientes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _value(ProgressMetricReadModel metric) {
    if (metric.value == null) return '—';
    final unit = metric.unit == null ? '' : ' ${metric.unit}';
    if (metric.target == null) {
      return '${metric.value!.toStringAsFixed(0)}$unit';
    }
    return '${metric.value!.toStringAsFixed(0)} / ${metric.target!.toStringAsFixed(0)}$unit';
  }
}

class HomeInsightSection extends StatelessWidget {
  const HomeInsightSection({
    required this.model,
    required this.onOpen,
    super.key,
  });

  final InsightFeedReadModel model;
  final ValueChanged<DeterministicInsightReadModel> onOpen;

  @override
  Widget build(BuildContext context) {
    if (model.insights.isEmpty) return const SizedBox.shrink();
    final insight = model.insights.first;
    return HomeSection(
      title: 'Insight do dia',
      child: HBCard(
        onTap: insight.deepLink == null ? null : () => onOpen(insight),
        semanticLabel: '${insight.title}. ${insight.message}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HBText(
              insight.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const HBGap.sm(),
            HBText(insight.message),
            const HBGap.sm(),
            HBText(
              insight.disclaimer,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class IntelligentQuickActionsSection extends StatelessWidget {
  const IntelligentQuickActionsSection({
    required this.model,
    required this.onAction,
    super.key,
  });

  final QuickActionsReadModel model;
  final ValueChanged<QuickActionReadModel> onAction;

  @override
  Widget build(BuildContext context) {
    final actions = [...model.fixed, ...model.dynamic];
    return HomeSection(
      title: 'Ações rápidas',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              QuickActionCard(
                icon: _icon(actions[index].id),
                title: actions[index].title,
                subtitle: index < model.fixed.length ? 'Registrar' : 'Resolver',
                onTap: () => onAction(actions[index]),
              ),
              if (index != actions.length - 1) const HBGap.md(),
            ],
          ],
        ),
      ),
    );
  }

  IconData _icon(String id) {
    if (id.contains('water')) return Icons.water_drop_outlined;
    if (id.contains('meal')) return Icons.restaurant_outlined;
    if (id.contains('weight')) return Icons.monitor_weight_outlined;
    if (id.contains('prescription')) return Icons.receipt_long_outlined;
    if (id.contains('treatment')) return Icons.medication_outlined;
    return Icons.calendar_month_outlined;
  }
}

class HomeFreshnessBanner extends StatelessWidget {
  const HomeFreshnessBanner({required this.status, super.key});
  final HomeSectionStatus status;

  @override
  Widget build(BuildContext context) {
    if (!status.freshness.isStale && !status.hasPendingSync) {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: HBCard(
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.textSecondary,
            ),
            const HBGap.sm(),
            Expanded(
              child: HBText(
                status.hasPendingSync
                    ? 'Dados locais disponíveis. Algumas atualizações aguardam sincronização.'
                    : 'Os dados locais podem estar desatualizados.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

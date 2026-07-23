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
    if (model.actions.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: 'Agora',
      subtitle: 'O que merece atenção neste momento.',
      child: Column(
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

class IntelligentAgendaSection extends StatefulWidget {
  const IntelligentAgendaSection({
    required this.model,
    required this.onItem,
    this.todayOnly,
    super.key,
  });

  final AgendaReadModel model;
  final ValueChanged<AgendaItemReadModel> onItem;
  final bool? todayOnly;

  @override
  State<IntelligentAgendaSection> createState() =>
      _IntelligentAgendaSectionState();
}

class _IntelligentAgendaSectionState extends State<IntelligentAgendaSection> {
  late bool _todayOnly = widget.todayOnly ?? true;

  @override
  Widget build(BuildContext context) {
    final today = widget.model.start;
    final items = widget.model.items
        .where((item) {
          final isToday =
              item.effectiveAt.year == today.year &&
              item.effectiveAt.month == today.month &&
              item.effectiveAt.day == today.day;
          return _todayOnly
              ? isToday
              : !isToday && item.effectiveAt.isAfter(today);
        })
        .toList(growable: false);
    return HomeSection(
      title: 'Seu dia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Hoje')),
              ButtonSegment(value: false, label: Text('Próximos 7 dias')),
            ],
            selected: {_todayOnly},
            onSelectionChanged: (value) =>
                setState(() => _todayOnly = value.first),
          ),
          const HBGap.md(),
          if (items.isEmpty)
            HBEmptyState(
              title: 'Nenhum item aplicável',
              description: _todayOnly
                  ? 'Não há ocorrências ou consultas para hoje.'
                  : 'Não há compromissos nos próximos sete dias.',
              icon: Icons.event_available_outlined,
            )
          else
            Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Semantics(
                    label: items[index].accessibilityLabel,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          child: HBText(
                            _time(items[index]),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Opacity(
                            opacity:
                                items[index].state == AgendaItemState.resolved
                                ? .62
                                : 1,
                            child: TodayTaskCard(
                              icon: _icon(items[index]),
                              title: items[index].title,
                              subtitle: _subtitle(items[index]),
                              onTap: () => widget.onItem(items[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != items.length - 1) const HBGap.sm(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _time(AgendaItemReadModel item) =>
      '${item.effectiveAt.hour.toString().padLeft(2, '0')}:${item.effectiveAt.minute.toString().padLeft(2, '0')}';

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
    if (_todayOnly) return state;
    final day = item.effectiveAt.day.toString().padLeft(2, '0');
    final month = item.effectiveAt.month.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute • $state';
  }
}

class DailyProgressSection extends StatelessWidget {
  const DailyProgressSection({required this.model, super.key});

  final ProgressSummaryReadModel model;

  @override
  Widget build(BuildContext context) {
    final metrics = [model.routine, model.water, model.protein];
    return HomeSection(
      title: 'Como está seu dia',
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
                subtitle: index < model.fixed.length ? 'Abrir' : 'Resolver',
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
    if (id.contains('vitamin')) return Icons.medication_liquid_outlined;
    if (id.contains('exam')) return Icons.science_outlined;
    if (id.contains('progress')) return Icons.trending_up_outlined;
    if (id.contains('profile')) return Icons.account_circle_outlined;
    if (id.contains('document')) return Icons.folder_outlined;
    if (id.contains('report')) return Icons.picture_as_pdf_outlined;
    if (id.contains('bioimpedance')) return Icons.monitor_heart_outlined;
    if (id.contains('academy')) return Icons.menu_book_outlined;
    if (id.contains('settings')) return Icons.settings_outlined;
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

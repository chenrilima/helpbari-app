import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import '../providers/baria_view_model_provider.dart';
import 'baria_message_list.dart';
import 'baria_suggestions_section.dart';
import 'baria_text_input.dart';

class BariaSheet extends ConsumerStatefulWidget {
  const BariaSheet({super.key});

  static Future<void> show(BuildContext context) => HBBottomSheet.show<void>(
    context,
    title: 'BarIA',
    useRootNavigator: true,
    child: const BariaSheet(),
  );

  @override
  ConsumerState<BariaSheet> createState() => _BariaSheetState();
}

class _BariaSheetState extends ConsumerState<BariaSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(bariaViewModelProvider.notifier).loadDailyInsight();
      await ref.read(bariaViewModelProvider.notifier).loadConversationHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bariaViewModelProvider);
    final now = state.context?.generatedAt ?? DateTime.now();
    final greeting = now.hour < 12
        ? 'Bom dia'
        : now.hour < 18
        ? 'Boa tarde'
        : 'Boa noite';
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HBText(
              '$greeting${state.context?.userName == null ? '' : ', ${state.context!.userName}'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const HBGap.sm(),
            HBText(
              'Hoje encontrei ${state.insights.length} ${state.insights.length == 1 ? 'insight' : 'insights'} para você.',
            ),
            const HBGap.lg(),
            if (state.isLoading && state.context == null)
              const HBLoading(message: 'Analisando seus registros...'),
            ...state.insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _InsightCard(insight: insight),
              ),
            ),
            const HBGap.lg(),
            HBText(
              'Converse com a BarIA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const HBGap.sm(),
            BariaSuggestionsSection(
              onSuggestionSelected: ref
                  .read(bariaViewModelProvider.notifier)
                  .handleSuggestion,
            ),
            if (state.conversationMessages.isNotEmpty) ...[
              const HBGap.md(),
              BariaMessageList(messages: state.conversationMessages),
            ],
            const HBGap.md(),
            BariaTextInput(
              isLoading: state.isLoading,
              onSendMessage: ref
                  .read(bariaViewModelProvider.notifier)
                  .sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final BariaInsight insight;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(AppRadius.md),
    onTap: insight.action.destination == null
        ? null
        : () {
            final destination = insight.action.destination!;
            Navigator.of(context).pop();
            context.push(destination);
          },
    child: HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color),
              const HBGap.horizontal(AppSpacing.sm),
              Expanded(
                child: HBText(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const HBGap.sm(),
          HBText(insight.description),
          const HBGap.xs(),
          HBText(
            'Fonte: ${insight.source}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (insight.action.label.isNotEmpty) ...[
            const HBGap.sm(),
            HBText(
              insight.action.label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    ),
  );

  Color get _color => switch (insight.priority) {
    BariaInsightPriority.critical => AppColors.danger,
    BariaInsightPriority.high => AppColors.warning,
    BariaInsightPriority.medium => AppColors.primary,
    BariaInsightPriority.low => AppColors.textSecondary,
  };
  IconData get _icon => switch (insight.category) {
    BariaInsightCategory.water => Icons.water_drop_outlined,
    BariaInsightCategory.weight => Icons.monitor_weight_outlined,
    BariaInsightCategory.vitamins ||
    BariaInsightCategory.medications => Icons.medication_outlined,
    BariaInsightCategory.appointments => Icons.event_outlined,
    BariaInsightCategory.academy => Icons.school_outlined,
    _ => Icons.auto_awesome_outlined,
  };
}

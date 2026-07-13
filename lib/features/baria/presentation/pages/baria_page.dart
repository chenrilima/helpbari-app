import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/baria_view_model_provider.dart';
import '../state/baria_state.dart';
import '../widgets/baria_daily_analysis_card.dart';
import '../widgets/baria_message_list.dart';
import '../widgets/baria_suggestions_section.dart';
import '../widgets/baria_text_input.dart';

class BariaPage extends ConsumerStatefulWidget {
  const BariaPage({super.key});

  @override
  ConsumerState<BariaPage> createState() => _BariaPageState();
}

class _BariaPageState extends ConsumerState<BariaPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await ref.read(bariaViewModelProvider.notifier).loadDailyInsight();
    await ref.read(bariaViewModelProvider.notifier).loadConversationHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bariaViewModelProvider);

    ref.listen<BariaState>(bariaViewModelProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        HBSnackBar.error(context, message: next.error!);
      }
    });

    if (state.isLoading &&
        state.dailyInsight == null &&
        state.conversationMessages.isEmpty) {
      return const HBPage(
        appBar: HBAppBar(title: 'BarIA'),
        children: [HBLoading(message: 'Preparando sua análise...')],
      );
    }

    return HBPage(
      appBar: HBAppBar(
        title: 'BarIA',
        subtitle: 'Sua assistente bariátrica inteligente',
      ),
      children: [
        if (state.error != null &&
            state.dailyInsight == null &&
            state.conversationMessages.isEmpty) ...[
          HBEmptyState(
            title: 'BarIA indisponível',
            description: state.error!,
            icon: Icons.error_outline,
            actionLabel: 'Tentar novamente',
            onActionPressed: _loadData,
          ),
          const HBGap.lg(),
        ],
        if (state.dailyInsight != null) ...[
          BariaDailyAnalysisCard(insight: state.dailyInsight!),
          const HBGap.xl(),
        ],
        BariaSuggestionsSection(
          onSuggestionSelected: (suggestion) {
            ref
                .read(bariaViewModelProvider.notifier)
                .handleSuggestion(suggestion);
          },
        ),
        const HBGap.lg(),
        if (state.conversationMessages.isNotEmpty) ...[
          BariaMessageList(messages: state.conversationMessages),
          const HBGap.lg(),
        ],
        if (state.conversationMessages.isEmpty && !state.isLoading) ...[
          const HBEmptyState(
            title: 'Conversa ainda não iniciada',
            description:
                'Escolha uma sugestão ou envie uma pergunta para começar.',
            icon: Icons.chat_bubble_outline,
          ),
          const HBGap.lg(),
        ],
        BariaTextInput(
          onSendMessage: (message) {
            ref.read(bariaViewModelProvider.notifier).sendMessage(message);
          },
          isLoading: state.isLoading,
        ),
      ],
    );
  }
}

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
      if (next.error != null) {
        HBSnackBar.error(context, message: next.error!);
      }
    });

    return HBPage(
      appBar: HBAppBar(
        title: 'BarIA',
        subtitle: 'Sua assistente bariátrica inteligente',
      ),
      children: [
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

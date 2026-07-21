import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/sync/sync.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../domain/models/models.dart';
import '../../domain/usecases/baria_use_cases.dart';
import '../providers/baria_use_cases_provider.dart';
import 'baria_state.dart';

class BariaViewModel extends Notifier<BariaState> {
  int _insightRequest = 0;
  BariaUseCases get _bariaUseCases => ref.read(bariaUseCasesProvider);
  ClockService get _clock => ref.read(clockServiceProvider);
  UuidService get _uuid => ref.read(uuidServiceProvider);

  @override
  BariaState build() {
    ref.listen(todayDashboardProvider, (previous, next) {
      if (previous != null && previous != next && next.hasValue) {
        unawaited(loadDailyInsight());
      }
    });
    ref.listen(syncManagerProvider, (previous, next) {
      if (previous?.lastSyncAt != next.lastSyncAt) {
        unawaited(loadDailyInsight());
      }
    });
    ref.listen(authSessionProvider, (previous, next) {
      if (previous?.id != next?.id) {
        state = const BariaState();
        if (next != null) unawaited(loadDailyInsight());
      }
    });
    return const BariaState();
  }

  Future<void> loadDailyInsight() async {
    final request = ++_insightRequest;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final values = await Future.wait<Object>([
        _bariaUseCases.getContext(),
        _bariaUseCases.getInsights(),
      ]);
      final context = values[0] as BariaContext;
      final insights = values[1] as List<BariaInsight>;
      final insight = insights.isEmpty
          ? await _bariaUseCases.getDailyInsight()
          : insights.first;
      if (request != _insightRequest) return;
      state = state.copyWith(
        dailyInsight: insight,
        context: context,
        insights: insights,
        isLoading: false,
      );
    } catch (e) {
      if (request != _insightRequest) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadConversationHistory() async {
    try {
      final messages = await _bariaUseCases.getConversationHistory();
      state = state.copyWith(conversationMessages: messages);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage(String userMessage) async {
    try {
      state = state.copyWith(clearError: true);
      // Save user message
      final userMsg = BariaMessage(
        id: _uuid.generate(),
        content: userMessage,
        timestamp: _clock.now(),
        isFromUser: true,
      );
      await _bariaUseCases.saveMessage(userMsg);

      // Update state with user message
      final updatedMessages = [...state.conversationMessages, userMsg];
      state = state.copyWith(
        conversationMessages: updatedMessages,
        isLoading: true,
      );

      // Generate and save response
      final response = await _bariaUseCases.generateResponse(userMessage);
      final responseMsg = BariaMessage(
        id: _uuid.generate(),
        content: response,
        timestamp: _clock.now(),
        isFromUser: false,
        action: _knowledgeAction(userMessage),
      );
      await _bariaUseCases.saveMessage(responseMsg);

      // Update state with response
      final finalMessages = [...updatedMessages, responseMsg];
      state = state.copyWith(
        conversationMessages: finalMessages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> handleSuggestion(String suggestion) async {
    await sendMessage(suggestion);
  }

  BariaInsightAction? _knowledgeAction(String query) {
    final normalized = query.toLowerCase();
    if (normalized.contains('faq') ||
        normalized.contains('pergunta frequente')) {
      return const BariaInsightAction(
        type: BariaInsightActionType.faq,
        label: 'Ver FAQ',
        destination: '/academy/faq',
      );
    }
    if (normalized.contains('glossário') || normalized.contains('glossario')) {
      return const BariaInsightAction(
        type: BariaInsightActionType.glossary,
        label: 'Ver glossário',
        destination: '/academy/glossary',
      );
    }
    for (final article in state.context?.recommendedArticles ?? const []) {
      final terms = <String>[
        article.title,
        article.categoryId,
        ...article.tags,
      ];
      if (terms.any((term) => normalized.contains(term.toLowerCase()))) {
        return BariaInsightAction(
          type: BariaInsightActionType.article,
          label: 'Ler artigo',
          destination: '/academy/article/${Uri.encodeComponent(article.id)}',
        );
      }
    }
    return null;
  }
}

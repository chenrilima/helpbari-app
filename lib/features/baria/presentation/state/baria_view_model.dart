import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../../domain/usecases/baria_use_cases.dart';
import '../providers/baria_use_cases_provider.dart';
import 'baria_state.dart';

class BariaViewModel extends Notifier<BariaState> {
  late final BariaUseCases _bariaUseCases;

  @override
  BariaState build() {
    _bariaUseCases = ref.read(bariaUseCasesProvider);
    return const BariaState();
  }

  Future<void> loadDailyInsight() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final insight = await _bariaUseCases.getDailyInsight();
      state = state.copyWith(dailyInsight: insight, isLoading: false);
    } catch (e) {
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
      // Save user message
      final userMsg = BariaMessage(
        id: DateTime.now().toIso8601String(),
        content: userMessage,
        timestamp: DateTime.now(),
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
        id: DateTime.now().toIso8601String(),
        content: response,
        timestamp: DateTime.now(),
        isFromUser: false,
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
}

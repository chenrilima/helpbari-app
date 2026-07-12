import '../models/models.dart';

abstract interface class BariaRepository {
  Future<BariaContext> getContext();
  Future<BariaInsight> getDailyInsight();

  Future<List<BariaMessage>> getConversationHistory();

  Future<void> saveMessage(BariaMessage message);

  Future<String> generateResponse(String userMessage);
}

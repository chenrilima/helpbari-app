import '../models/models.dart';
import '../repositories/baria_repository.dart';

class BariaUseCases {
  const BariaUseCases(this._repository);

  final BariaRepository _repository;

  Future<BariaContext> getContext() => _repository.getContext();

  Future<BariaInsight> getDailyInsight() {
    return _repository.getDailyInsight();
  }

  Future<List<BariaMessage>> getConversationHistory() {
    return _repository.getConversationHistory();
  }

  Future<void> saveMessage(BariaMessage message) {
    return _repository.saveMessage(message);
  }

  Future<String> generateResponse(String userMessage) {
    return _repository.generateResponse(userMessage);
  }
}

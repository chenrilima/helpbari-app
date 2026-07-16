import '../models/models.dart';
import '../../../academy/domain/entities/entities.dart';

abstract interface class BarIAContextProvider {
  Future<BariaContext> getContext({bool forceRefresh = false});
  void invalidate();
}

abstract interface class BarIAKnowledgeProvider {
  Future<List<KnowledgeArticle>> recommendedArticles(BariaContext context);
  Future<List<KnowledgeArticle>> search(String query, {int limit = 3});
}

abstract interface class BarIAConversationProvider {
  Future<List<BariaMessage>> history();
  Future<void> save(BariaMessage message);
}

abstract interface class BarIAResponder {
  Future<String> respond(String message, BariaContext context);
}

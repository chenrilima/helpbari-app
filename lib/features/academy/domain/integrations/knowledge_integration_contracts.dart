import '../entities/entities.dart';

abstract interface class BariaKnowledgePort {
  Future<List<KnowledgeArticle>> findContext({
    required String topic,
    int limit = 3,
  });
}

abstract interface class HomeKnowledgePort {
  Future<List<KnowledgeArticle>> getSuggestedArticles({int limit = 3});
}

abstract interface class NotificationKnowledgePort {
  Future<KnowledgeArticle?> getArticleForNotification(String articleId);
}

abstract interface class ReportKnowledgePort {
  Future<List<KnowledgeReference>> getReferencesForArticles(
    Set<String> articleIds,
  );
}

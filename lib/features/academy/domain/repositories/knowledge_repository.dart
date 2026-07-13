import '../entities/entities.dart';
import '../models/models.dart';

abstract interface class KnowledgeRepository {
  Future<KnowledgeCatalog> loadCatalog({bool forceRefresh = false});

  Future<KnowledgePage> getArticles(KnowledgeQuery query);

  Future<KnowledgeArticle> getArticle(String articleId);

  Future<List<KnowledgeArticle>> getRelatedArticles(String articleId);

  Future<KnowledgeUserData> getUserData();

  Future<bool> toggleFavorite(String articleId);

  Future<KnowledgeProgress> saveProgress({
    required String articleId,
    required int lastBlockIndex,
    required int totalBlocks,
  });

  Future<KnowledgeHistoryEntry> recordArticleOpened(String articleId);
}

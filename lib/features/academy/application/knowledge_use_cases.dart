import '../domain/entities/entities.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';

class KnowledgeUseCases {
  const KnowledgeUseCases(this._repository);

  final KnowledgeRepository _repository;

  Future<KnowledgeCatalog> loadCatalog({bool forceRefresh = false}) {
    return _repository.loadCatalog(forceRefresh: forceRefresh);
  }

  Future<KnowledgePage> getArticles(KnowledgeQuery query) {
    return _repository.getArticles(query);
  }

  Future<KnowledgeArticle> getArticle(String articleId) {
    return _repository.getArticle(articleId);
  }

  Future<List<KnowledgeArticle>> getRelatedArticles(String articleId) {
    return _repository.getRelatedArticles(articleId);
  }

  Future<KnowledgeUserData> getUserData() => _repository.getUserData();

  Future<bool> toggleFavorite(String articleId) {
    return _repository.toggleFavorite(articleId);
  }

  Future<KnowledgeProgress> saveProgress({
    required String articleId,
    required int lastBlockIndex,
    required int totalBlocks,
  }) {
    return _repository.saveProgress(
      articleId: articleId,
      lastBlockIndex: lastBlockIndex,
      totalBlocks: totalBlocks,
    );
  }

  Future<KnowledgeHistoryEntry> recordArticleOpened(String articleId) {
    return _repository.recordArticleOpened(articleId);
  }
}

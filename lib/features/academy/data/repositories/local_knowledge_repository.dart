import '../../domain/entities/entities.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/datasources.dart';
import '../storage/storage.dart';

final class LocalKnowledgeRepository implements KnowledgeRepository {
  LocalKnowledgeRepository({
    required KnowledgeContentDatasource datasource,
    required KnowledgeLocalStore localStore,
    DateTime Function()? now,
  }) : _datasource = datasource,
       _localStore = localStore,
       _now = now ?? DateTime.now;

  static const maximumHistoryEntries = 100;

  final KnowledgeContentDatasource _datasource;
  final KnowledgeLocalStore _localStore;
  final DateTime Function() _now;
  KnowledgeCatalog? _catalog;

  @override
  Future<KnowledgeCatalog> loadCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _catalog != null) return _catalog!;
    final catalog = await _datasource.loadCatalog();
    _catalog = catalog;
    return catalog;
  }

  @override
  Future<KnowledgePage> getArticles(KnowledgeQuery query) async {
    final catalog = await loadCatalog();
    final userData = await _localStore.read();
    final normalizedSearch = _normalize(query.searchTerm);
    final filtered = catalog.articles
        .where((article) {
          if (normalizedSearch.isNotEmpty &&
              !_searchText(article).contains(normalizedSearch)) {
            return false;
          }
          final filter = query.filter;
          if (filter.categoryId != null &&
              article.categoryId != filter.categoryId) {
            return false;
          }
          if (!_intersects(article.bariatricPhases, filter.bariatricPhases) ||
              !_intersects(article.surgeryTypes, filter.surgeryTypes) ||
              !_intersects(article.tags, filter.tags)) {
            return false;
          }
          if (filter.evidenceLevels.isNotEmpty &&
              !filter.evidenceLevels.contains(article.evidenceLevel)) {
            return false;
          }
          if (filter.favoritesOnly &&
              !userData.favoriteArticleIds.contains(article.id)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    final start = (query.page - 1) * query.pageSize;
    final items = start >= filtered.length
        ? const <KnowledgeArticle>[]
        : filtered.sublist(
            start,
            (start + query.pageSize).clamp(0, filtered.length),
          );
    return KnowledgePage(
      items: items,
      page: query.page,
      pageSize: query.pageSize,
      totalItems: filtered.length,
    );
  }

  @override
  Future<KnowledgeArticle> getArticle(String articleId) async {
    final catalog = await loadCatalog();
    for (final article in catalog.articles) {
      if (article.id == articleId) return article;
    }
    throw StateError('Knowledge article not found: $articleId');
  }

  @override
  Future<List<KnowledgeArticle>> getRelatedArticles(String articleId) async {
    final article = await getArticle(articleId);
    final catalog = await loadCatalog();
    final byId = <String, KnowledgeArticle>{
      for (final item in catalog.articles) item.id: item,
    };
    return article.relatedArticleIds
        .map((id) => byId[id])
        .whereType<KnowledgeArticle>()
        .toList(growable: false);
  }

  @override
  Future<KnowledgeUserData> getUserData() => _localStore.read();

  @override
  Future<bool> toggleFavorite(String articleId) async {
    await getArticle(articleId);
    final current = await _localStore.read();
    final favorites = current.favoriteArticleIds.toSet();
    final isFavorite = favorites.add(articleId);
    if (!isFavorite) favorites.remove(articleId);
    await _localStore.write(
      KnowledgeUserData(
        favoriteArticleIds: favorites,
        progressByArticleId: current.progressByArticleId,
        history: current.history,
      ),
    );
    return isFavorite;
  }

  @override
  Future<KnowledgeProgress> saveProgress({
    required String articleId,
    required int lastBlockIndex,
    required int totalBlocks,
  }) async {
    await getArticle(articleId);
    if (lastBlockIndex < 0 || totalBlocks <= 0) {
      throw ArgumentError('Invalid article progress');
    }
    final current = await _localStore.read();
    final progress = KnowledgeProgress(
      articleId: articleId,
      lastBlockIndex: lastBlockIndex,
      completedPercent: ((lastBlockIndex + 1) / totalBlocks).clamp(0, 1),
      updatedAt: _now().toUtc(),
    );
    await _localStore.write(
      KnowledgeUserData(
        favoriteArticleIds: current.favoriteArticleIds,
        progressByArticleId: <String, KnowledgeProgress>{
          ...current.progressByArticleId,
          articleId: progress,
        },
        history: current.history,
      ),
    );
    return progress;
  }

  @override
  Future<KnowledgeHistoryEntry> recordArticleOpened(String articleId) async {
    await getArticle(articleId);
    final current = await _localStore.read();
    KnowledgeHistoryEntry? previous;
    for (final item in current.history) {
      if (item.articleId == articleId) previous = item;
    }
    final entry = KnowledgeHistoryEntry(
      articleId: articleId,
      lastReadAt: _now().toUtc(),
      readCount: (previous?.readCount ?? 0) + 1,
    );
    final history = <KnowledgeHistoryEntry>[
      entry,
      ...current.history.where((item) => item.articleId != articleId),
    ].take(maximumHistoryEntries).toList(growable: false);
    await _localStore.write(
      KnowledgeUserData(
        favoriteArticleIds: current.favoriteArticleIds,
        progressByArticleId: current.progressByArticleId,
        history: history,
      ),
    );
    return entry;
  }

  static bool _intersects(List<String> values, Set<String> filter) {
    return filter.isEmpty || values.any(filter.contains);
  }

  static String _searchText(KnowledgeArticle article) {
    final parts = <String>[
      article.title,
      article.subtitle,
      article.summary,
      ...article.tags,
      ...article.blocks.expand(
        (block) => <String>[
          if (block.title != null) block.title!,
          if (block.content != null) block.content!,
          ...block.items,
          ...block.checklistItems.map((item) => item.text),
        ],
      ),
      ...article.faq.expand((faq) => <String>[faq.question, faq.answer]),
    ];
    return _normalize(parts.join(' '));
  }

  static String _normalize(String input) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

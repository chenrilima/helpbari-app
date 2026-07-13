import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/academy/data/datasources/datasources.dart';
import 'package:helpbari/features/academy/data/repositories/local_knowledge_repository.dart';
import 'package:helpbari/features/academy/data/storage/knowledge_local_store.dart';
import 'package:helpbari/features/academy/domain/entities/entities.dart';
import 'package:helpbari/features/academy/domain/models/models.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MemoryKnowledgeLocalStore store;
  late LocalKnowledgeRepository repository;

  setUp(() {
    store = _MemoryKnowledgeLocalStore();
    repository = LocalKnowledgeRepository(
      datasource: _FakeAssetDatasource(_catalog('asset')),
      localStore: store,
      now: () => DateTime.utc(2026, 7, 13, 12),
    );
  });

  test('search is local, full-text and accent insensitive', () async {
    final result = await repository.getArticles(
      const KnowledgeQuery(searchTerm: 'hidratacao segura'),
    );

    expect(result.items.map((article) => article.id), <String>['hydration']);
  });

  test('combines category, phase, surgery, tag and evidence filters', () async {
    final result = await repository.getArticles(
      const KnowledgeQuery(
        filter: KnowledgeFilter(
          categoryId: 'nutrition',
          bariatricPhases: <String>{'manutenção'},
          surgeryTypes: <String>{'sleeve'},
          tags: <String>{'proteína'},
          evidenceLevels: <KnowledgeEvidenceLevel>{KnowledgeEvidenceLevel.high},
        ),
      ),
    );

    expect(result.items.single.id, 'protein');
  });

  test('paginates locally', () async {
    final first = await repository.getArticles(
      const KnowledgeQuery(pageSize: 1),
    );
    final second = await repository.getArticles(
      const KnowledgeQuery(page: 2, pageSize: 1),
    );

    expect(first.items, hasLength(1));
    expect(first.hasNextPage, isTrue);
    expect(second.items.single.id, isNot(first.items.single.id));
  });

  test('favorites are persisted and can be filtered', () async {
    expect(await repository.toggleFavorite('protein'), isTrue);
    final favorites = await repository.getArticles(
      const KnowledgeQuery(filter: KnowledgeFilter(favoritesOnly: true)),
    );

    expect(favorites.items.single.id, 'protein');
    expect(store.data.favoriteArticleIds, contains('protein'));
    expect(await repository.toggleFavorite('protein'), isFalse);
  });

  test('progress is persisted with a bounded percentage', () async {
    final progress = await repository.saveProgress(
      articleId: 'hydration',
      lastBlockIndex: 9,
      totalBlocks: 3,
    );

    expect(progress.completedPercent, 1);
    expect(store.data.progressByArticleId['hydration'], same(progress));
  });

  test(
    'history increments reads, moves article to front and persists',
    () async {
      await repository.recordArticleOpened('protein');
      await repository.recordArticleOpened('hydration');
      final latest = await repository.recordArticleOpened('protein');

      expect(latest.readCount, 2);
      expect(store.data.history.first.articleId, 'protein');
      expect(store.data.history, hasLength(2));
    },
  );

  test(
    'content datasource can be swapped without changing repository contract',
    () async {
      final remoteRepository = LocalKnowledgeRepository(
        datasource: _FakeRemoteDatasource(_catalog('remote')),
        localStore: store,
      );

      final catalog = await remoteRepository.loadCatalog();

      expect(catalog.contentVersion, 'remote');
    },
  );

  test(
    'shared preferences store round-trips only user interaction data',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final localStore = SharedPreferencesKnowledgeLocalStore(
        SharedPreferencesLocalStorageService(preferences),
      );
      final data = KnowledgeUserData(
        favoriteArticleIds: const <String>{'hydration'},
        progressByArticleId: <String, KnowledgeProgress>{
          'hydration': KnowledgeProgress(
            articleId: 'hydration',
            lastBlockIndex: 1,
            completedPercent: 0.5,
            updatedAt: DateTime.utc(2026, 7, 13),
          ),
        },
        history: <KnowledgeHistoryEntry>[
          KnowledgeHistoryEntry(
            articleId: 'hydration',
            lastReadAt: DateTime.utc(2026, 7, 13),
            readCount: 2,
          ),
        ],
      );

      await localStore.write(data);
      final restored = await localStore.read();

      expect(restored.favoriteArticleIds, data.favoriteArticleIds);
      expect(restored.progressByArticleId['hydration']?.completedPercent, 0.5);
      expect(restored.history.single.readCount, 2);
      expect(preferences.getKeys(), <String>{localStore.storageKey});
    },
  );
}

KnowledgeCatalog _catalog(String version) {
  return KnowledgeCatalog(
    schemaVersion: 1,
    contentVersion: version,
    categories: const <KnowledgeCategory>[
      KnowledgeCategory(id: 'hydration', name: 'Hidratação', description: 'D'),
      KnowledgeCategory(id: 'nutrition', name: 'Nutrição', description: 'D'),
    ],
    articles: <KnowledgeArticle>[
      _article(
        id: 'hydration',
        title: 'Hidratação segura',
        category: 'hydration',
        tags: const <String>['água'],
        evidence: KnowledgeEvidenceLevel.moderate,
      ),
      _article(
        id: 'protein',
        title: 'Proteína na manutenção',
        category: 'nutrition',
        tags: const <String>['proteína'],
        evidence: KnowledgeEvidenceLevel.high,
      ),
      _article(
        id: 'vitamins',
        title: 'Vitaminas',
        category: 'nutrition',
        tags: const <String>['vitaminas'],
        evidence: KnowledgeEvidenceLevel.consensus,
      ),
    ],
    faq: const <KnowledgeFaq>[],
    glossary: const <KnowledgeGlossaryEntry>[],
    references: const <KnowledgeReference>[],
  );
}

KnowledgeArticle _article({
  required String id,
  required String title,
  required String category,
  required List<String> tags,
  required KnowledgeEvidenceLevel evidence,
}) {
  return KnowledgeArticle(
    id: id,
    title: title,
    subtitle: 'Subtítulo',
    summary: 'Resumo do artigo',
    blocks: const <KnowledgeBlock>[
      KnowledgeBlock(
        id: 'block',
        type: KnowledgeBlockType.markdown,
        content: 'Conteúdo',
      ),
    ],
    faq: const <KnowledgeFaq>[],
    tags: tags,
    categoryId: category,
    bariatricPhases: const <String>['manutenção'],
    surgeryTypes: const <String>['sleeve'],
    readingTimeMinutes: 3,
    relatedArticleIds: const <String>[],
    sources: const <KnowledgeReference>[
      KnowledgeReference(
        id: 'ref',
        title: 'Reference',
        authors: 'Author',
        year: 2026,
      ),
    ],
    evidenceLevel: evidence,
    lastReviewedAt: DateTime.utc(2026, 7, 1),
    medicalDisclaimer: 'Aviso.',
  );
}

class _MemoryKnowledgeLocalStore implements KnowledgeLocalStore {
  KnowledgeUserData data = const KnowledgeUserData();

  @override
  Future<KnowledgeUserData> read() async => data;

  @override
  Future<void> write(KnowledgeUserData data) async => this.data = data;
}

class _FakeAssetDatasource implements KnowledgeContentDatasource {
  const _FakeAssetDatasource(this.catalog);

  final KnowledgeCatalog catalog;

  @override
  Future<KnowledgeCatalog> loadCatalog() async => catalog;
}

class _FakeRemoteDatasource implements RemoteKnowledgeDatasource {
  const _FakeRemoteDatasource(this.catalog);

  final KnowledgeCatalog catalog;

  @override
  Future<KnowledgeCatalog> loadCatalog() async => catalog;
}

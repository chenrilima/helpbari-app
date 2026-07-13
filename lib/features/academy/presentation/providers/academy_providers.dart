import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../application/knowledge_use_cases.dart';
import '../../data/datasources/datasources.dart';
import '../../data/repositories/repositories.dart';
import '../../data/storage/storage.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../states/academy_state.dart';
import '../viewmodels/academy_view_model.dart';

final knowledgeAssetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

final knowledgeContentDatasourceProvider = Provider<KnowledgeContentDatasource>(
  (ref) =>
      AssetKnowledgeDatasource(bundle: ref.watch(knowledgeAssetBundleProvider)),
);

final knowledgeLocalStoreProvider = Provider<KnowledgeLocalStore>((ref) {
  return SharedPreferencesKnowledgeLocalStore(
    ref.watch(localStorageServiceProvider),
    userScope: ref.watch(authSessionProvider)?.id ?? 'anonymous',
  );
});

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  return LocalKnowledgeRepository(
    datasource: ref.watch(knowledgeContentDatasourceProvider),
    localStore: ref.watch(knowledgeLocalStoreProvider),
    now: () => ref.read(clockServiceProvider).now(),
  );
});

final knowledgeUseCasesProvider = Provider<KnowledgeUseCases>((ref) {
  return KnowledgeUseCases(ref.watch(knowledgeRepositoryProvider));
});

final academyViewModelProvider =
    NotifierProvider<AcademyViewModel, AcademyState>(AcademyViewModel.new);

final knowledgeCatalogProvider = FutureProvider<KnowledgeCatalog>((ref) {
  return ref.watch(knowledgeUseCasesProvider).loadCatalog();
});

final knowledgeUserDataProvider = FutureProvider<KnowledgeUserData>((ref) {
  return ref.watch(knowledgeUseCasesProvider).getUserData();
});

final knowledgeArticleProvider =
    FutureProvider.family<KnowledgeArticle, String>(
      (ref, articleId) =>
          ref.watch(knowledgeUseCasesProvider).getArticle(articleId),
    );

final relatedKnowledgeArticlesProvider =
    FutureProvider.family<List<KnowledgeArticle>, String>(
      (ref, articleId) =>
          ref.watch(knowledgeUseCasesProvider).getRelatedArticles(articleId),
    );

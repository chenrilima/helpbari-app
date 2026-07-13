import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/models.dart';
import '../providers/academy_providers.dart';
import '../states/academy_state.dart';

class AcademyViewModel extends Notifier<AcademyState> {
  static const pageSize = 20;

  @override
  AcademyState build() => const AcademyState();

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final useCases = ref.read(knowledgeUseCasesProvider);
      final catalog = await useCases.loadCatalog(forceRefresh: forceRefresh);
      final userData = await useCases.getUserData();
      final page = await useCases.getArticles(
        KnowledgeQuery(
          searchTerm: state.searchTerm,
          filter: state.filter,
          pageSize: pageSize,
        ),
      );
      state = state.copyWith(
        catalog: catalog,
        articles: page.items,
        userData: userData,
        currentPage: page.page,
        totalItems: page.totalItems,
        hasNextPage: page.hasNextPage,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> search(String term) async {
    state = state.copyWith(searchTerm: term);
    await _reloadArticles();
  }

  Future<void> applyFilter(KnowledgeFilter filter) async {
    state = state.copyWith(filter: filter);
    await _reloadArticles();
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasNextPage) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await ref
          .read(knowledgeUseCasesProvider)
          .getArticles(
            KnowledgeQuery(
              searchTerm: state.searchTerm,
              filter: state.filter,
              page: state.currentPage + 1,
              pageSize: pageSize,
            ),
          );
      state = state.copyWith(
        articles: [...state.articles, ...page.items],
        currentPage: page.page,
        totalItems: page.totalItems,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> toggleFavorite(String articleId) async {
    final isFavorite = await ref
        .read(knowledgeUseCasesProvider)
        .toggleFavorite(articleId);
    final userData = await ref.read(knowledgeUseCasesProvider).getUserData();
    state = state.copyWith(userData: userData);
    ref.invalidate(knowledgeUserDataProvider);
    if (state.filter.favoritesOnly) await _reloadArticles();
    return isFavorite;
  }

  Future<void> recordArticleOpened(String articleId) async {
    await ref.read(knowledgeUseCasesProvider).recordArticleOpened(articleId);
    state = state.copyWith(
      userData: await ref.read(knowledgeUseCasesProvider).getUserData(),
    );
    ref.invalidate(knowledgeUserDataProvider);
  }

  Future<void> completeArticle(String articleId, int totalBlocks) async {
    await ref
        .read(knowledgeUseCasesProvider)
        .saveProgress(
          articleId: articleId,
          lastBlockIndex: totalBlocks - 1,
          totalBlocks: totalBlocks,
        );
    state = state.copyWith(
      userData: await ref.read(knowledgeUseCasesProvider).getUserData(),
    );
    ref.invalidate(knowledgeUserDataProvider);
  }

  Future<void> _reloadArticles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref
          .read(knowledgeUseCasesProvider)
          .getArticles(
            KnowledgeQuery(
              searchTerm: state.searchTerm,
              filter: state.filter,
              pageSize: pageSize,
            ),
          );
      state = state.copyWith(
        articles: page.items,
        currentPage: page.page,
        totalItems: page.totalItems,
        hasNextPage: page.hasNextPage,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

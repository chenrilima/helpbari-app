import '../../domain/entities/entities.dart';
import '../../domain/models/models.dart';

class AcademyState {
  const AcademyState({
    this.catalog,
    this.articles = const <KnowledgeArticle>[],
    this.userData = const KnowledgeUserData(),
    this.searchTerm = '',
    this.filter = const KnowledgeFilter(),
    this.currentPage = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final KnowledgeCatalog? catalog;
  final List<KnowledgeArticle> articles;
  final KnowledgeUserData userData;
  final String searchTerm;
  final KnowledgeFilter filter;
  final int currentPage;
  final int totalItems;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasLoaded;
  final String? errorMessage;

  AcademyState copyWith({
    KnowledgeCatalog? catalog,
    List<KnowledgeArticle>? articles,
    KnowledgeUserData? userData,
    String? searchTerm,
    KnowledgeFilter? filter,
    int? currentPage,
    int? totalItems,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AcademyState(
      catalog: catalog ?? this.catalog,
      articles: articles ?? this.articles,
      userData: userData ?? this.userData,
      searchTerm: searchTerm ?? this.searchTerm,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

import '../entities/entities.dart';

class KnowledgeFilter {
  const KnowledgeFilter({
    this.categoryId,
    this.bariatricPhases = const <String>{},
    this.surgeryTypes = const <String>{},
    this.tags = const <String>{},
    this.evidenceLevels = const <KnowledgeEvidenceLevel>{},
    this.favoritesOnly = false,
  });

  final String? categoryId;
  final Set<String> bariatricPhases;
  final Set<String> surgeryTypes;
  final Set<String> tags;
  final Set<KnowledgeEvidenceLevel> evidenceLevels;
  final bool favoritesOnly;

  bool get isEmpty =>
      categoryId == null &&
      bariatricPhases.isEmpty &&
      surgeryTypes.isEmpty &&
      tags.isEmpty &&
      evidenceLevels.isEmpty &&
      !favoritesOnly;

  KnowledgeFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    Set<String>? bariatricPhases,
    Set<String>? surgeryTypes,
    Set<String>? tags,
    Set<KnowledgeEvidenceLevel>? evidenceLevels,
    bool? favoritesOnly,
  }) {
    return KnowledgeFilter(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      bariatricPhases: bariatricPhases ?? this.bariatricPhases,
      surgeryTypes: surgeryTypes ?? this.surgeryTypes,
      tags: tags ?? this.tags,
      evidenceLevels: evidenceLevels ?? this.evidenceLevels,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

class KnowledgeQuery {
  const KnowledgeQuery({
    this.searchTerm = '',
    this.filter = const KnowledgeFilter(),
    this.page = 1,
    this.pageSize = 20,
  }) : assert(page > 0),
       assert(pageSize > 0);

  final String searchTerm;
  final KnowledgeFilter filter;
  final int page;
  final int pageSize;
}

class KnowledgePage {
  const KnowledgePage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
  });

  final List<KnowledgeArticle> items;
  final int page;
  final int pageSize;
  final int totalItems;

  bool get hasNextPage => page * pageSize < totalItems;
}

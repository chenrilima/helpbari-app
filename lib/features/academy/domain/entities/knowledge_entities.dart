enum KnowledgeBlockType {
  heading,
  markdown,
  list,
  checklist,
  quote,
  warning,
  medicalAlert,
  faq,
  table,
  image,
}

enum KnowledgeEvidenceLevel { consensus, low, moderate, high }

class KnowledgeCategory {
  const KnowledgeCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class KnowledgeFaq {
  const KnowledgeFaq({
    required this.id,
    required this.question,
    required this.answer,
    this.articleId,
    this.categoryId,
  });

  final String id;
  final String question;
  final String answer;
  final String? articleId;
  final String? categoryId;
}

class KnowledgeGlossaryEntry {
  const KnowledgeGlossaryEntry({
    required this.id,
    required this.term,
    required this.definition,
    this.relatedTerms = const <String>[],
  });

  final String id;
  final String term;
  final String definition;
  final List<String> relatedTerms;
}

class KnowledgeReference {
  const KnowledgeReference({
    required this.id,
    required this.title,
    required this.authors,
    required this.year,
    this.url,
  });

  final String id;
  final String title;
  final String authors;
  final int year;
  final String? url;
}

class KnowledgeChecklistItem {
  const KnowledgeChecklistItem({
    required this.text,
    this.initiallyChecked = false,
  });

  final String text;
  final bool initiallyChecked;
}

class KnowledgeTable {
  const KnowledgeTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

class KnowledgeImage {
  const KnowledgeImage({
    required this.assetPath,
    required this.altText,
    this.caption,
  });

  final String assetPath;
  final String altText;
  final String? caption;
}

class KnowledgeBlock {
  const KnowledgeBlock({
    required this.id,
    required this.type,
    this.title,
    this.content,
    this.items = const <String>[],
    this.checklistItems = const <KnowledgeChecklistItem>[],
    this.faqIds = const <String>[],
    this.table,
    this.image,
  });

  final String id;
  final KnowledgeBlockType type;
  final String? title;
  final String? content;
  final List<String> items;
  final List<KnowledgeChecklistItem> checklistItems;
  final List<String> faqIds;
  final KnowledgeTable? table;
  final KnowledgeImage? image;
}

class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.blocks,
    required this.faq,
    required this.tags,
    required this.categoryId,
    required this.bariatricPhases,
    required this.surgeryTypes,
    required this.readingTimeMinutes,
    required this.relatedArticleIds,
    required this.sources,
    required this.evidenceLevel,
    required this.lastReviewedAt,
    required this.medicalDisclaimer,
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
  final List<KnowledgeBlock> blocks;
  final List<KnowledgeFaq> faq;
  final List<String> tags;
  final String categoryId;
  final List<String> bariatricPhases;
  final List<String> surgeryTypes;
  final int readingTimeMinutes;
  final List<String> relatedArticleIds;
  final List<KnowledgeReference> sources;
  final KnowledgeEvidenceLevel evidenceLevel;
  final DateTime lastReviewedAt;
  final String medicalDisclaimer;
}

class KnowledgeCatalog {
  const KnowledgeCatalog({
    required this.schemaVersion,
    required this.contentVersion,
    required this.categories,
    required this.articles,
    required this.faq,
    required this.glossary,
    required this.references,
  });

  final int schemaVersion;
  final String contentVersion;
  final List<KnowledgeCategory> categories;
  final List<KnowledgeArticle> articles;
  final List<KnowledgeFaq> faq;
  final List<KnowledgeGlossaryEntry> glossary;
  final List<KnowledgeReference> references;
}

class KnowledgeProgress {
  const KnowledgeProgress({
    required this.articleId,
    required this.lastBlockIndex,
    required this.completedPercent,
    required this.updatedAt,
  });

  final String articleId;
  final int lastBlockIndex;
  final double completedPercent;
  final DateTime updatedAt;
}

class KnowledgeHistoryEntry {
  const KnowledgeHistoryEntry({
    required this.articleId,
    required this.lastReadAt,
    required this.readCount,
  });

  final String articleId;
  final DateTime lastReadAt;
  final int readCount;
}

class KnowledgeUserData {
  const KnowledgeUserData({
    this.favoriteArticleIds = const <String>{},
    this.progressByArticleId = const <String, KnowledgeProgress>{},
    this.history = const <KnowledgeHistoryEntry>[],
  });

  final Set<String> favoriteArticleIds;
  final Map<String, KnowledgeProgress> progressByArticleId;
  final List<KnowledgeHistoryEntry> history;
}

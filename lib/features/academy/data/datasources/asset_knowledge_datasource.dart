import 'package:flutter/services.dart';

import '../../domain/entities/entities.dart';
import '../parsers/knowledge_json_parser.dart';
import 'knowledge_content_datasource.dart';

final class AssetKnowledgeDatasource implements KnowledgeContentDatasource {
  const AssetKnowledgeDatasource({
    required AssetBundle bundle,
    this.manifestPath = 'assets/knowledge/manifest.json',
  }) : _bundle = bundle;

  final AssetBundle _bundle;
  final String manifestPath;

  @override
  Future<KnowledgeCatalog> loadCatalog() async {
    final manifest = KnowledgeJsonParser.parseManifest(
      await _bundle.loadString(manifestPath),
    );
    final documents = await Future.wait<String>([
      _bundle.loadString(manifest.categoryPath),
      _bundle.loadString(manifest.faqPath),
      _bundle.loadString(manifest.glossaryPath),
      _bundle.loadString(manifest.referencePath),
    ]);
    final references = KnowledgeJsonParser.parseReferences(documents[3]);
    _ensureUniqueIds(
      references.map((reference) => reference.id),
      label: 'reference',
    );
    final referencesById = <String, KnowledgeReference>{
      for (final reference in references) reference.id: reference,
    };
    final articleDocuments = await Future.wait<String>(
      manifest.articlePaths.map(_bundle.loadString),
    );
    final articles = articleDocuments
        .map(
          (source) => KnowledgeJsonParser.parseArticle(
            source,
            referencesById: referencesById,
          ),
        )
        .toList(growable: false);
    final categories = KnowledgeJsonParser.parseCategories(documents[0]);
    final faq = KnowledgeJsonParser.parseFaq(documents[1]);
    final glossary = KnowledgeJsonParser.parseGlossary(documents[2]);
    _validateRelationships(
      categories: categories,
      articles: articles,
      faq: faq,
      glossary: glossary,
    );
    await _ensureImageAssetsExist(articles);

    return KnowledgeCatalog(
      schemaVersion: manifest.schemaVersion,
      contentVersion: manifest.contentVersion,
      categories: categories,
      articles: articles,
      faq: faq,
      glossary: glossary,
      references: references,
    );
  }

  static void _validateRelationships({
    required List<KnowledgeCategory> categories,
    required List<KnowledgeArticle> articles,
    required List<KnowledgeFaq> faq,
    required List<KnowledgeGlossaryEntry> glossary,
  }) {
    _ensureUniqueIds(
      categories.map((category) => category.id),
      label: 'category',
    );
    _ensureUniqueIds(articles.map((article) => article.id), label: 'article');
    _ensureUniqueIds(faq.map((item) => item.id), label: 'FAQ');
    _ensureUniqueIds(
      glossary.map((entry) => entry.id),
      label: 'glossary entry',
    );
    _ensureUniqueValues(
      glossary.map((entry) => entry.term),
      label: 'glossary term',
    );
    final categoryIds = categories.map((category) => category.id).toSet();
    final articleIds = articles.map((article) => article.id).toSet();
    final allFaq = <KnowledgeFaq>[
      ...faq,
      ...articles.expand((article) => article.faq),
    ];
    _ensureUniqueIds(allFaq.map((item) => item.id), label: 'FAQ');

    for (final item in allFaq) {
      if (item.categoryId != null && !categoryIds.contains(item.categoryId)) {
        throw FormatException(
          'FAQ ${item.id} has unknown category ${item.categoryId}',
        );
      }
      if (item.articleId != null && !articleIds.contains(item.articleId)) {
        throw FormatException(
          'FAQ ${item.id} has unknown article ${item.articleId}',
        );
      }
    }

    for (final article in articles) {
      if (!categoryIds.contains(article.categoryId)) {
        throw FormatException(
          'Article ${article.id} has unknown category ${article.categoryId}',
        );
      }
      final unknownRelated = article.relatedArticleIds.where(
        (relatedId) => !articleIds.contains(relatedId),
      );
      if (unknownRelated.isNotEmpty) {
        throw FormatException(
          'Article ${article.id} has unknown related article ${unknownRelated.first}',
        );
      }
      if (article.relatedArticleIds.contains(article.id)) {
        throw FormatException('Article ${article.id} cannot relate to itself');
      }
      for (final item in article.faq) {
        if (item.articleId != article.id) {
          throw FormatException(
            'FAQ ${item.id} must belong to article ${article.id}',
          );
        }
      }
      _ensureUniqueIds(
        article.blocks.map((block) => block.id),
        label: 'block in article ${article.id}',
      );
      final availableFaqIds = <String>{
        ...faq
            .where(
              (item) => item.articleId == null || item.articleId == article.id,
            )
            .map((item) => item.id),
        ...article.faq.map((item) => item.id),
      };
      final referencedFaqIds = article.blocks
          .expand((block) => block.faqIds)
          .toList(growable: false);
      _ensureUniqueIds(
        referencedFaqIds,
        label: 'referenced FAQ in article ${article.id}',
      );
      final unknownFaqIds = referencedFaqIds.where(
        (faqId) => !availableFaqIds.contains(faqId),
      );
      if (unknownFaqIds.isNotEmpty) {
        throw FormatException(
          'Article ${article.id} has unknown FAQ ${unknownFaqIds.first}',
        );
      }
    }

    final glossaryTerms = glossary.map((entry) => entry.term).toSet();
    for (final entry in glossary) {
      if (entry.relatedTerms.toSet().length != entry.relatedTerms.length) {
        throw FormatException(
          'Glossary entry ${entry.id} has duplicate related terms',
        );
      }
      final unknownTerms = entry.relatedTerms.where(
        (term) => !glossaryTerms.contains(term),
      );
      if (unknownTerms.isNotEmpty) {
        throw FormatException(
          'Glossary entry ${entry.id} has unknown related term ${unknownTerms.first}',
        );
      }
      if (entry.relatedTerms.contains(entry.term)) {
        throw FormatException(
          'Glossary entry ${entry.id} cannot relate to itself',
        );
      }
    }
  }

  Future<void> _ensureImageAssetsExist(List<KnowledgeArticle> articles) async {
    final paths = articles
        .expand((article) => article.blocks)
        .map((block) => block.image?.assetPath)
        .whereType<String>()
        .toSet();
    for (final path in paths) {
      try {
        await _bundle.load(path);
      } on Object catch (error) {
        throw FormatException('Missing knowledge image asset: $path', error);
      }
    }
  }

  static void _ensureUniqueIds(Iterable<String> ids, {required String label}) {
    final values = ids.toList(growable: false);
    if (values.toSet().length != values.length) {
      throw FormatException('Duplicate $label id');
    }
  }

  static void _ensureUniqueValues(
    Iterable<String> values, {
    required String label,
  }) {
    final items = values.toList(growable: false);
    if (items.toSet().length != items.length) {
      throw FormatException('Duplicate $label');
    }
  }
}

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
    final categoryIds = categories.map((category) => category.id).toSet();
    final articleIds = articles.map((article) => article.id).toSet();
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
      _ensureUniqueIds(
        article.blocks.map((block) => block.id),
        label: 'block in article ${article.id}',
      );
      final availableFaqIds = <String>{
        ...faq.map((item) => item.id),
        ...article.faq.map((item) => item.id),
      };
      final unknownFaqIds = article.blocks
          .expand((block) => block.faqIds)
          .where((faqId) => !availableFaqIds.contains(faqId));
      if (unknownFaqIds.isNotEmpty) {
        throw FormatException(
          'Article ${article.id} has unknown FAQ ${unknownFaqIds.first}',
        );
      }
    }
  }

  static void _ensureUniqueIds(Iterable<String> ids, {required String label}) {
    final values = ids.toList(growable: false);
    if (values.toSet().length != values.length) {
      throw FormatException('Duplicate $label id');
    }
  }
}

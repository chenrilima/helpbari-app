import 'dart:convert';

import '../../domain/entities/entities.dart';

class KnowledgeManifestData {
  const KnowledgeManifestData({
    required this.schemaVersion,
    required this.contentVersion,
    required this.categoryPath,
    required this.articlePaths,
    required this.faqPath,
    required this.glossaryPath,
    required this.referencePath,
  });

  final int schemaVersion;
  final String contentVersion;
  final String categoryPath;
  final List<String> articlePaths;
  final String faqPath;
  final String glossaryPath;
  final String referencePath;
}

abstract final class KnowledgeJsonParser {
  static KnowledgeManifestData parseManifest(String source) {
    final json = _object(jsonDecode(source), 'manifest');
    final schemaVersion = _integer(json, 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException('Unsupported knowledge schema: $schemaVersion');
    }
    return KnowledgeManifestData(
      schemaVersion: schemaVersion,
      contentVersion: _string(json, 'contentVersion'),
      categoryPath: _string(json, 'categories'),
      articlePaths: _strings(json, 'articles', allowEmpty: true),
      faqPath: _string(json, 'faq'),
      glossaryPath: _string(json, 'glossary'),
      referencePath: _string(json, 'references'),
    );
  }

  static List<KnowledgeCategory> parseCategories(String source) {
    final items = _arrayFromDocument(source, 'categories');
    return items
        .map((item) {
          final json = _object(item, 'category');
          return KnowledgeCategory(
            id: _string(json, 'id'),
            name: _string(json, 'name'),
            description: _string(json, 'description'),
          );
        })
        .toList(growable: false);
  }

  static List<KnowledgeFaq> parseFaq(String source) {
    return _arrayFromDocument(
      source,
      'items',
    ).map((item) => _faq(_object(item, 'faq'))).toList(growable: false);
  }

  static List<KnowledgeGlossaryEntry> parseGlossary(String source) {
    return _arrayFromDocument(source, 'items')
        .map((item) {
          final json = _object(item, 'glossary entry');
          return KnowledgeGlossaryEntry(
            id: _string(json, 'id'),
            term: _string(json, 'term'),
            definition: _string(json, 'definition'),
            relatedTerms: _optionalStrings(json, 'relatedTerms'),
          );
        })
        .toList(growable: false);
  }

  static List<KnowledgeReference> parseReferences(String source) {
    return _arrayFromDocument(source, 'items')
        .map((item) {
          final json = _object(item, 'reference');
          return KnowledgeReference(
            id: _string(json, 'id'),
            title: _string(json, 'title'),
            authors: _string(json, 'authors'),
            year: _integer(json, 'year'),
            url: _optionalString(json, 'url'),
          );
        })
        .toList(growable: false);
  }

  static KnowledgeArticle parseArticle(
    String source, {
    required Map<String, KnowledgeReference> referencesById,
  }) {
    final json = _object(jsonDecode(source), 'article');
    final id = _string(json, 'id');
    final sourceIds = _strings(json, 'sources');
    final sources = sourceIds
        .map((sourceId) {
          final reference = referencesById[sourceId];
          if (reference == null) {
            throw FormatException('Article $id has unknown source: $sourceId');
          }
          return reference;
        })
        .toList(growable: false);
    final blocks = _list(json, 'blocks')
        .map((item) => _block(_object(item, 'block'), articleId: id))
        .toList(growable: false);
    if (blocks.isEmpty) {
      throw FormatException('Article $id must contain at least one block');
    }

    return KnowledgeArticle(
      id: id,
      title: _string(json, 'title'),
      subtitle: _string(json, 'subtitle'),
      summary: _string(json, 'summary'),
      blocks: blocks,
      faq: _optionalList(json, 'faq')
          .map((item) => _faq(_object(item, 'article faq'), articleId: id))
          .toList(growable: false),
      tags: _strings(json, 'tags'),
      categoryId: _string(json, 'categoryId'),
      bariatricPhases: _strings(json, 'bariatricPhases'),
      surgeryTypes: _strings(json, 'surgeryTypes'),
      readingTimeMinutes: _positiveInteger(json, 'readingTimeMinutes'),
      relatedArticleIds: _optionalStrings(json, 'relatedArticleIds'),
      sources: sources,
      evidenceLevel: _enumByName(
        KnowledgeEvidenceLevel.values,
        _string(json, 'evidenceLevel'),
        'evidenceLevel',
      ),
      lastReviewedAt: _date(json, 'lastReviewedAt'),
      medicalDisclaimer: _string(json, 'medicalDisclaimer'),
    );
  }

  static KnowledgeFaq _faq(Map<String, Object?> json, {String? articleId}) {
    return KnowledgeFaq(
      id: _string(json, 'id'),
      question: _string(json, 'question'),
      answer: _string(json, 'answer'),
      articleId: _optionalString(json, 'articleId') ?? articleId,
      categoryId: _optionalString(json, 'categoryId'),
    );
  }

  static KnowledgeBlock _block(
    Map<String, Object?> json, {
    required String articleId,
  }) {
    final id = _string(json, 'id');
    final type = _enumByName(
      KnowledgeBlockType.values,
      _string(json, 'type'),
      'block type',
    );
    final tableJson = json['table'];
    final imageJson = json['image'];
    final block = KnowledgeBlock(
      id: id,
      type: type,
      title: _optionalString(json, 'title'),
      content: _optionalString(json, 'content'),
      items: _optionalStrings(json, 'items'),
      checklistItems: _optionalList(json, 'checklistItems')
          .map((item) {
            final checklist = _object(item, 'checklist item');
            return KnowledgeChecklistItem(
              text: _string(checklist, 'text'),
              initiallyChecked: _optionalBool(checklist, 'initiallyChecked'),
            );
          })
          .toList(growable: false),
      faqIds: _optionalStrings(json, 'faqIds'),
      table: tableJson == null
          ? null
          : _table(_object(tableJson, 'table'), articleId: articleId),
      image: imageJson == null ? null : _image(_object(imageJson, 'image')),
    );
    _validateBlock(block, articleId: articleId);
    return block;
  }

  static KnowledgeTable _table(
    Map<String, Object?> json, {
    required String articleId,
  }) {
    final headers = _strings(json, 'headers');
    final rows = _list(json, 'rows')
        .map((row) {
          if (row is! List<Object?>) {
            throw FormatException(
              'Article $articleId has an invalid table row',
            );
          }
          final values = row
              .map((cell) {
                if (cell is! String || cell.trim().isEmpty) {
                  throw FormatException(
                    'Article $articleId has an invalid table cell',
                  );
                }
                return cell.trim();
              })
              .toList(growable: false);
          if (values.length != headers.length) {
            throw FormatException('Article $articleId has an uneven table row');
          }
          return values;
        })
        .toList(growable: false);
    if (rows.isEmpty) {
      throw FormatException('Article $articleId has an empty table');
    }
    return KnowledgeTable(headers: headers, rows: rows);
  }

  static KnowledgeImage _image(Map<String, Object?> json) {
    return KnowledgeImage(
      assetPath: _string(json, 'assetPath'),
      altText: _string(json, 'altText'),
      caption: _optionalString(json, 'caption'),
    );
  }

  static void _validateBlock(
    KnowledgeBlock block, {
    required String articleId,
  }) {
    final hasContent = block.content?.isNotEmpty ?? false;
    final valid = switch (block.type) {
      KnowledgeBlockType.heading ||
      KnowledgeBlockType.markdown ||
      KnowledgeBlockType.quote ||
      KnowledgeBlockType.warning ||
      KnowledgeBlockType.medicalAlert => hasContent,
      KnowledgeBlockType.list => block.items.isNotEmpty,
      KnowledgeBlockType.checklist => block.checklistItems.isNotEmpty,
      KnowledgeBlockType.faq => block.faqIds.isNotEmpty,
      KnowledgeBlockType.table => block.table != null,
      KnowledgeBlockType.image => block.image != null,
    };
    if (!valid) {
      throw FormatException(
        'Article $articleId has invalid ${block.type.name} block ${block.id}',
      );
    }
  }

  static List<Object?> _arrayFromDocument(String source, String key) {
    final json = _object(jsonDecode(source), '$key document');
    return _list(json, key);
  }

  static Map<String, Object?> _object(Object? value, String label) {
    if (value is! Map<String, Object?>) {
      throw FormatException('Invalid $label object');
    }
    return value;
  }

  static List<Object?> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List<Object?>) throw FormatException('Invalid $key list');
    return value;
  }

  static List<Object?> _optionalList(Map<String, Object?> json, String key) {
    if (!json.containsKey(key)) return const <Object?>[];
    return _list(json, key);
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value.trim();
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    if (!json.containsKey(key) || json[key] == null) return null;
    return _string(json, key);
  }

  static int _integer(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('Invalid $key');
    return value;
  }

  static int _positiveInteger(Map<String, Object?> json, String key) {
    final value = _integer(json, key);
    if (value <= 0) throw FormatException('Invalid $key');
    return value;
  }

  static bool _optionalBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return false;
    if (value is! bool) throw FormatException('Invalid $key');
    return value;
  }

  static List<String> _strings(
    Map<String, Object?> json,
    String key, {
    bool allowEmpty = false,
  }) {
    final values = _list(json, key)
        .map((value) {
          if (value is! String || value.trim().isEmpty) {
            throw FormatException('Invalid value in $key');
          }
          return value.trim();
        })
        .toList(growable: false);
    if (!allowEmpty && values.isEmpty) throw FormatException('Empty $key');
    return values;
  }

  static List<String> _optionalStrings(Map<String, Object?> json, String key) {
    if (!json.containsKey(key)) return const <String>[];
    return _strings(json, key, allowEmpty: true);
  }

  static DateTime _date(Map<String, Object?> json, String key) {
    final value = _string(json, key);
    final date = DateTime.tryParse(value);
    if (date == null) throw FormatException('Invalid $key');
    return date;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    String label,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Invalid $label: $name');
  }
}

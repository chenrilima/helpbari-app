import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/academy/data/datasources/asset_knowledge_datasource.dart';
import 'package:helpbari/features/academy/data/parsers/knowledge_json_parser.dart';
import 'package:helpbari/features/academy/domain/entities/entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reference = KnowledgeReference(
    id: 'ref-1',
    title: 'Reference',
    authors: 'Author',
    year: 2026,
  );

  group('KnowledgeJsonParser', () {
    test('parses every supported article field and block type', () {
      final article = KnowledgeJsonParser.parseArticle(
        _articleJson(),
        referencesById: const <String, KnowledgeReference>{'ref-1': reference},
      );

      expect(article.title, 'Hidratação segura');
      expect(article.subtitle, isNotEmpty);
      expect(article.summary, isNotEmpty);
      expect(article.blocks.map((block) => block.type), {
        ...KnowledgeBlockType.values,
      });
      expect(article.faq.single.question, 'Posso beber rápido?');
      expect(article.tags, contains('hidratação'));
      expect(article.bariatricPhases, contains('manutenção'));
      expect(article.surgeryTypes, contains('sleeve'));
      expect(article.sources.single.id, 'ref-1');
      expect(article.evidenceLevel, KnowledgeEvidenceLevel.high);
      expect(article.medicalDisclaimer, isNotEmpty);
    });

    test('parses FAQ and glossary documents', () {
      final faq = KnowledgeJsonParser.parseFaq(
        '{"items":[{"id":"f1","question":"Q?","answer":"A."}]}',
      );
      final glossary = KnowledgeJsonParser.parseGlossary(
        '{"items":[{"id":"g1","term":"Sleeve","definition":"Definição","relatedTerms":[]}]}',
      );

      expect(faq.single.question, 'Q?');
      expect(glossary.single.term, 'Sleeve');
    });

    test('rejects an invalid article', () {
      final invalid = jsonDecode(_articleJson()) as Map<String, Object?>;
      invalid['readingTimeMinutes'] = 0;

      expect(
        () => KnowledgeJsonParser.parseArticle(
          jsonEncode(invalid),
          referencesById: const <String, KnowledgeReference>{
            'ref-1': reference,
          },
        ),
        throwsFormatException,
      );
    });

    test('rejects an article without a source', () {
      final invalid = jsonDecode(_articleJson()) as Map<String, Object?>;
      invalid['sources'] = <Object?>[];

      expect(
        () => KnowledgeJsonParser.parseArticle(
          jsonEncode(invalid),
          referencesById: const <String, KnowledgeReference>{
            'ref-1': reference,
          },
        ),
        throwsFormatException,
      );
    });
  });

  test('asset datasource loads the full catalog without network access', () async {
    final bundle = _MemoryAssetBundle(<String, String>{
      'manifest.json': jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'contentVersion': 'test',
        'categories': 'categories.json',
        'articles': <String>['article.json'],
        'faq': 'faq.json',
        'glossary': 'glossary.json',
        'references': 'references.json',
      }),
      'categories.json':
          '{"categories":[{"id":"hydration","name":"Hidratação","description":"Descrição"}]}',
      'article.json': _articleJson(),
      'faq.json': '{"items":[]}',
      'glossary.json': '{"items":[]}',
      'references.json':
          '{"items":[{"id":"ref-1","title":"Reference","authors":"Author","year":2026}]}',
    });

    final catalog = await AssetKnowledgeDatasource(
      bundle: bundle,
      manifestPath: 'manifest.json',
    ).loadCatalog();

    expect(catalog.articles.single.id, 'article-1');
    expect(
      bundle.loadedPaths,
      containsAll(<String>{
        'manifest.json',
        'categories.json',
        'article.json',
        'faq.json',
        'glossary.json',
        'references.json',
      }),
    );
  });

  test('bundled knowledge assets form a valid offline catalog', () async {
    final catalog = await AssetKnowledgeDatasource(
      bundle: rootBundle,
    ).loadCatalog();

    expect(catalog.schemaVersion, 1);
    expect(catalog.articles, isNotEmpty);
    expect(catalog.categories, isNotEmpty);
    expect(catalog.references, isNotEmpty);
  });
}

String _articleJson() => jsonEncode(<String, Object?>{
  'id': 'article-1',
  'title': 'Hidratação segura',
  'subtitle': 'Subtítulo',
  'summary': 'Resumo',
  'blocks': <Object?>[
    <String, Object?>{'id': 'b1', 'type': 'heading', 'content': 'Título'},
    <String, Object?>{'id': 'b2', 'type': 'markdown', 'content': '**Texto**'},
    <String, Object?>{
      'id': 'b3',
      'type': 'list',
      'items': <String>['Item'],
    },
    <String, Object?>{
      'id': 'b4',
      'type': 'checklist',
      'checklistItems': <Object?>[
        <String, Object?>{'text': 'Checar'},
      ],
    },
    <String, Object?>{'id': 'b5', 'type': 'quote', 'content': 'Citação'},
    <String, Object?>{'id': 'b6', 'type': 'warning', 'content': 'Aviso'},
    <String, Object?>{'id': 'b7', 'type': 'medicalAlert', 'content': 'Alerta'},
    <String, Object?>{
      'id': 'b8',
      'type': 'faq',
      'faqIds': <String>['f1'],
    },
    <String, Object?>{
      'id': 'b9',
      'type': 'table',
      'table': <String, Object?>{
        'headers': <String>['A'],
        'rows': <Object?>[
          <String>['B'],
        ],
      },
    },
    <String, Object?>{
      'id': 'b10',
      'type': 'image',
      'image': <String, Object?>{
        'assetPath': 'future.webp',
        'altText': 'Imagem futura',
      },
    },
  ],
  'faq': <Object?>[
    <String, Object?>{
      'id': 'f1',
      'question': 'Posso beber rápido?',
      'answer': 'Siga sua equipe.',
    },
  ],
  'tags': <String>['hidratação'],
  'categoryId': 'hydration',
  'bariatricPhases': <String>['manutenção'],
  'surgeryTypes': <String>['sleeve'],
  'readingTimeMinutes': 5,
  'relatedArticleIds': <String>[],
  'sources': <String>['ref-1'],
  'evidenceLevel': 'high',
  'lastReviewedAt': '2026-07-01',
  'medicalDisclaimer': 'Aviso médico.',
});

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this._assets);

  final Map<String, String> _assets;
  final Set<String> loadedPaths = <String>{};

  @override
  Future<ByteData> load(String key) async {
    loadedPaths.add(key);
    final source = _assets[key];
    if (source == null) throw StateError('Missing asset: $key');
    final bytes = Uint8List.fromList(utf8.encode(source));
    return ByteData.view(bytes.buffer);
  }
}

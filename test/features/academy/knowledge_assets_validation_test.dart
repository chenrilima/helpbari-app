import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/academy/data/datasources/asset_knowledge_datasource.dart';
import 'package:helpbari/features/academy/data/parsers/knowledge_json_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'knowledge assets match the complete manifest and final schema',
    () async {
      const knowledgeRoot = 'assets/knowledge';
      const manifestPath = '$knowledgeRoot/manifest.json';
      final manifest = KnowledgeJsonParser.parseManifest(
        File(manifestPath).readAsStringSync(),
      );

      final articlePaths =
          Directory('$knowledgeRoot/articles')
              .listSync()
              .whereType<File>()
              .map((file) => file.path)
              .where((path) => path.endsWith('.json'))
              .toList(growable: false)
            ..sort();
      expect(manifest.articlePaths, orderedEquals(articlePaths));

      final manifestJsonPaths = <String>{
        manifestPath,
        manifest.categoryPath,
        ...manifest.articlePaths,
        manifest.faqPath,
        manifest.glossaryPath,
        manifest.referencePath,
      };
      final existingJsonPaths = Directory(knowledgeRoot)
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => path.endsWith('.json'))
          .toSet();
      expect(existingJsonPaths, unorderedEquals(manifestJsonPaths));
      for (final path in manifestJsonPaths) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Missing manifest: $path',
        );
      }

      final catalog = await AssetKnowledgeDatasource(
        bundle: rootBundle,
      ).loadCatalog();
      final today = DateTime.now().toUtc();
      final endOfToday = DateTime.utc(
        today.year,
        today.month,
        today.day,
        23,
        59,
        59,
      );
      for (final article in catalog.articles) {
        expect(
          '$knowledgeRoot/articles/${article.id}.json',
          isIn(manifest.articlePaths),
          reason:
              'Article ID is its canonical slug and must match its filename',
        );
        expect(
          article.sources,
          isNotEmpty,
          reason: '${article.id} has no source',
        );
        expect(
          article.lastReviewedAt.isAfter(endOfToday),
          isFalse,
          reason: '${article.id} has a future review date',
        );
      }

      final referencedImages = catalog.articles
          .expand((article) => article.blocks)
          .map((block) => block.image?.assetPath)
          .whereType<String>()
          .toSet();
      final imagesDirectory = Directory('$knowledgeRoot/images');
      final existingImages = imagesDirectory.existsSync()
          ? imagesDirectory
                .listSync(recursive: true)
                .whereType<File>()
                .map((file) => file.path)
                .toSet()
          : <String>{};
      expect(existingImages, unorderedEquals(referencedImages));
    },
  );
}

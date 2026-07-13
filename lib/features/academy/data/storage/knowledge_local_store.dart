import 'dart:convert';

import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/entities.dart';

abstract interface class KnowledgeLocalStore {
  Future<KnowledgeUserData> read();

  Future<void> write(KnowledgeUserData data);
}

final class SharedPreferencesKnowledgeLocalStore
    implements KnowledgeLocalStore {
  const SharedPreferencesKnowledgeLocalStore(
    this._storage, {
    this.userScope = 'anonymous',
  });

  static const storageKeyPrefix = 'academy.user_data';

  final LocalStorageService _storage;
  final String userScope;

  String get storageKey => '$storageKeyPrefix.$userScope.v1';

  @override
  Future<KnowledgeUserData> read() async {
    final source = _storage.getString(storageKey);
    if (source == null || source.isEmpty) return const KnowledgeUserData();
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, Object?>) return const KnowledgeUserData();
      final favorites = _strings(json['favorites']).toSet();
      final progress = <String, KnowledgeProgress>{};
      final progressJson = json['progress'];
      if (progressJson is Map<String, Object?>) {
        for (final entry in progressJson.entries) {
          final value = entry.value;
          if (value is! Map<String, Object?>) continue;
          final updatedAt = DateTime.tryParse(
            value['updatedAt'] as String? ?? '',
          );
          final index = value['lastBlockIndex'];
          final percent = value['completedPercent'];
          if (updatedAt == null || index is! int || percent is! num) continue;
          progress[entry.key] = KnowledgeProgress(
            articleId: entry.key,
            lastBlockIndex: index,
            completedPercent: percent.toDouble().clamp(0, 1),
            updatedAt: updatedAt,
          );
        }
      }
      final history = <KnowledgeHistoryEntry>[];
      final historyJson = json['history'];
      if (historyJson is List<Object?>) {
        for (final item in historyJson) {
          if (item is! Map<String, Object?>) continue;
          final articleId = item['articleId'];
          final readCount = item['readCount'];
          final lastReadAt = DateTime.tryParse(
            item['lastReadAt'] as String? ?? '',
          );
          if (articleId is! String || readCount is! int || lastReadAt == null) {
            continue;
          }
          history.add(
            KnowledgeHistoryEntry(
              articleId: articleId,
              lastReadAt: lastReadAt,
              readCount: readCount,
            ),
          );
        }
      }
      return KnowledgeUserData(
        favoriteArticleIds: favorites,
        progressByArticleId: progress,
        history: history,
      );
    } on FormatException {
      return const KnowledgeUserData();
    } on TypeError {
      return const KnowledgeUserData();
    }
  }

  @override
  Future<void> write(KnowledgeUserData data) async {
    final json = <String, Object?>{
      'favorites': data.favoriteArticleIds.toList()..sort(),
      'progress': <String, Object?>{
        for (final entry in data.progressByArticleId.entries)
          entry.key: <String, Object?>{
            'lastBlockIndex': entry.value.lastBlockIndex,
            'completedPercent': entry.value.completedPercent,
            'updatedAt': entry.value.updatedAt.toUtc().toIso8601String(),
          },
      },
      'history': data.history
          .map(
            (entry) => <String, Object?>{
              'articleId': entry.articleId,
              'lastReadAt': entry.lastReadAt.toUtc().toIso8601String(),
              'readCount': entry.readCount,
            },
          )
          .toList(growable: false),
    };
    await _storage.setString(storageKey, jsonEncode(json));
  }

  static List<String> _strings(Object? value) {
    if (value is! List<Object?>) return const <String>[];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }
}

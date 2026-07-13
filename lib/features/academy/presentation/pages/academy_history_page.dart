import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/academy_providers.dart';
import '../widgets/knowledge_article_card.dart';

class AcademyHistoryPage extends ConsumerWidget {
  const AcademyHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(knowledgeCatalogProvider);
    final userData = ref.watch(knowledgeUserDataProvider);
    return HBPage(
      scrollable: false,
      appBar: const HBAppBar(title: 'Histórico de leitura'),
      children: [
        Expanded(
          child: catalog.when(
            loading: () => const HBLoading(message: 'Carregando histórico...'),
            error: (_, _) => _error(ref),
            data: (value) => userData.when(
              loading: () =>
                  const HBLoading(message: 'Carregando histórico...'),
              error: (_, _) => _error(ref),
              data: (interactions) =>
                  _HistoryList(catalog: value, userData: interactions),
            ),
          ),
        ),
      ],
    );
  }

  Widget _error(WidgetRef ref) {
    return HBEmptyState(
      title: 'Histórico indisponível',
      description: 'Não foi possível carregar os dados locais de leitura.',
      actionLabel: 'Tentar novamente',
      onActionPressed: () {
        ref.invalidate(knowledgeCatalogProvider);
        ref.invalidate(knowledgeUserDataProvider);
      },
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.catalog, required this.userData});

  final KnowledgeCatalog catalog;
  final KnowledgeUserData userData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesById = <String, KnowledgeArticle>{
      for (final article in catalog.articles) article.id: article,
    };
    final articles = userData.history
        .map((entry) => articlesById[entry.articleId])
        .whereType<KnowledgeArticle>()
        .toList(growable: false);
    if (articles.isEmpty) {
      return const HBEmptyState(
        icon: Icons.history,
        title: 'Histórico vazio',
        description: 'Os artigos abertos aparecerão aqui.',
      );
    }
    return ListView.separated(
      itemCount: articles.length,
      separatorBuilder: (_, _) => const HBGap.md(),
      itemBuilder: (context, index) {
        final article = articles[index];
        return KnowledgeArticleCard(
          article: article,
          isFavorite: userData.favoriteArticleIds.contains(article.id),
          progress: userData.progressByArticleId[article.id],
          onTap: () => context.push(AppRoutes.academyArticlePath(article.id)),
          onFavoritePressed: () async {
            await ref
                .read(academyViewModelProvider.notifier)
                .toggleFavorite(article.id);
            ref.invalidate(knowledgeUserDataProvider);
          },
        );
      },
    );
  }
}

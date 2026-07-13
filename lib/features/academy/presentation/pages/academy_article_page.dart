import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/academy_providers.dart';
import '../widgets/knowledge_article_card.dart';
import '../widgets/knowledge_block_renderer.dart';

class AcademyArticlePage extends ConsumerStatefulWidget {
  const AcademyArticlePage({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<AcademyArticlePage> createState() => _AcademyArticlePageState();
}

class _AcademyArticlePageState extends ConsumerState<AcademyArticlePage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(academyViewModelProvider.notifier)
          .recordArticleOpened(widget.articleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = ref.watch(knowledgeArticleProvider(widget.articleId));
    final state = ref.watch(academyViewModelProvider);
    return article.when(
      loading: () => const HBPage(
        appBar: HBAppBar(title: 'Artigo'),
        children: [Expanded(child: HBLoading(message: 'Abrindo artigo...'))],
      ),
      error: (_, _) => HBPage(
        appBar: const HBAppBar(title: 'Artigo'),
        children: [
          Expanded(
            child: HBEmptyState(
              icon: Icons.error_outline,
              title: 'Artigo indisponível',
              description: 'Não foi possível carregar este conteúdo local.',
              actionLabel: 'Tentar novamente',
              onActionPressed: () =>
                  ref.invalidate(knowledgeArticleProvider(widget.articleId)),
            ),
          ),
        ],
      ),
      data: (value) => HBPage(
        appBar: HBAppBar(
          title: value.title,
          subtitle: '${value.readingTimeMinutes} min de leitura',
          actions: [
            IconButton(
              tooltip: state.userData.favoriteArticleIds.contains(value.id)
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: () => ref
                  .read(academyViewModelProvider.notifier)
                  .toggleFavorite(value.id),
              icon: Icon(
                state.userData.favoriteArticleIds.contains(value.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
            ),
          ],
        ),
        children: [Expanded(child: _ArticleContent(article: value))],
      ),
    );
  }
}

class _ArticleContent extends ConsumerWidget {
  const _ArticleContent({required this.article});

  final KnowledgeArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(knowledgeCatalogProvider).value;
    final faqById = <String, KnowledgeFaq>{
      if (catalog != null)
        for (final faq in catalog.faq) faq.id: faq,
      for (final faq in article.faq) faq.id: faq,
    };
    final progress = ref
        .watch(academyViewModelProvider)
        .userData
        .progressByArticleId[article.id];
    return ListView(
      children: [
        HBText(article.subtitle, style: Theme.of(context).textTheme.titleLarge),
        const HBGap.sm(),
        HBText(
          article.summary,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const HBGap.lg(),
        for (final block in article.blocks) ...[
          KnowledgeBlockRenderer(block: block, faqById: faqById),
          const HBGap.lg(),
        ],
        if (article.faq.isNotEmpty) ...[
          HBSection(
            title: 'Perguntas frequentes',
            child: Column(
              children: article.faq
                  .map(
                    (faq) => HBCard(
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: HBText(faq.question),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: HBText(faq.answer),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const HBGap.lg(),
        ],
        HBCard(
          borderColor: AppColors.danger,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.danger,
              ),
              const HBGap.horizontal(AppSpacing.md),
              Expanded(child: HBText(article.medicalDisclaimer)),
            ],
          ),
        ),
        const HBGap.lg(),
        HBSection(
          title: 'Fontes',
          subtitle: 'Última revisão: ${_formatDate(article.lastReviewedAt)}',
          child: Column(
            children: article.sources
                .map(
                  (source) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: HBText(
                      '${source.authors} (${source.year}). ${source.title}',
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const HBGap.lg(),
        HBButton(
          label: progress?.completedPercent == 1
              ? 'Artigo concluído'
              : 'Marcar como concluído',
          icon: Icons.check_circle_outline,
          onPressed: progress?.completedPercent == 1
              ? null
              : () async {
                  await ref
                      .read(academyViewModelProvider.notifier)
                      .completeArticle(article.id, article.blocks.length);
                  if (context.mounted) {
                    HBSnackBar.success(
                      context,
                      message: 'Progresso de leitura salvo.',
                    );
                  }
                },
        ),
        const HBGap.xl(),
        _RelatedArticles(articleId: article.id),
        const HBGap.xl(),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _RelatedArticles extends ConsumerWidget {
  const _RelatedArticles({required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedKnowledgeArticlesProvider(articleId));
    return related.when(
      loading: () =>
          const HBLoading(message: 'Buscando artigos relacionados...'),
      error: (_, _) => const SizedBox.shrink(),
      data: (articles) {
        if (articles.isEmpty) return const SizedBox.shrink();
        final userData = ref.watch(academyViewModelProvider).userData;
        return HBSection(
          title: 'Artigos relacionados',
          child: Column(
            children: articles
                .map(
                  (article) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: KnowledgeArticleCard(
                      article: article,
                      isFavorite: userData.favoriteArticleIds.contains(
                        article.id,
                      ),
                      progress: userData.progressByArticleId[article.id],
                      onTap: () => context.pushReplacement(
                        AppRoutes.academyArticlePath(article.id),
                      ),
                      onFavoritePressed: () => ref
                          .read(academyViewModelProvider.notifier)
                          .toggleFavorite(article.id),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import '../providers/academy_providers.dart';
import '../states/academy_state.dart';
import '../widgets/knowledge_article_card.dart';
import '../widgets/knowledge_filter_sheet.dart';

class AcademyPage extends ConsumerStatefulWidget {
  const AcademyPage({super.key});

  @override
  ConsumerState<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends ConsumerState<AcademyPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(academyViewModelProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(academyViewModelProvider);
    ref.listen(academyViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage &&
          next.articles.isNotEmpty) {
        HBSnackBar.error(
          context,
          message: 'Não foi possível concluir a operação.',
        );
      }
    });

    return HBPage(
      appBar: HBAppBar(
        title: 'Academia Bariátrica',
        subtitle: 'Conhecimento confiável, sempre offline',
        actions: [
          IconButton(
            tooltip: 'Histórico de leitura',
            onPressed: () => context.push(AppRoutes.academyHistory),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Perguntas frequentes',
            onPressed: () => context.push(AppRoutes.academyFaq),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'Glossário',
            onPressed: () => context.push(AppRoutes.academyGlossary),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: HBTextField(
                controller: _searchController,
                label: 'Buscar na Academia',
                hint: 'Ex.: hidratação, proteína, vitaminas',
                prefixIcon: Icons.search,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
              ),
            ),
            const HBGap.horizontal(AppSpacing.sm),
            IconButton.filledTonal(
              tooltip: 'Filtros',
              onPressed: state.catalog == null ? null : () => _showFilters(),
              icon: Badge(
                isLabelVisible: !state.filter.isEmpty,
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        const HBGap.md(),
        Expanded(child: _body(state)),
      ],
    );
  }

  Widget _body(AcademyState state) {
    if (state.isLoading && state.articles.isEmpty) {
      return const HBLoading(message: 'Carregando a Academia...');
    }
    if (state.errorMessage != null && state.articles.isEmpty) {
      return HBEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível abrir a Academia',
        description: 'Os conteúdos locais não puderam ser carregados.',
        actionLabel: 'Tentar novamente',
        onActionPressed: () => ref
            .read(academyViewModelProvider.notifier)
            .load(forceRefresh: true),
      );
    }
    if (state.articles.isEmpty) {
      return HBEmptyState(
        icon: Icons.search_off,
        title: 'Nenhum artigo encontrado',
        description:
            'Altere a busca ou limpe os filtros para tentar novamente.',
        actionLabel: 'Limpar filtros',
        onActionPressed: () {
          _searchController.clear();
          ref
              .read(academyViewModelProvider.notifier)
              .search('')
              .then(
                (_) => ref
                    .read(academyViewModelProvider.notifier)
                    .applyFilter(const KnowledgeFilter()),
              );
        },
      );
    }
    return ListView.separated(
      itemCount: state.articles.length + (state.hasNextPage ? 1 : 0),
      separatorBuilder: (_, _) => const HBGap.md(),
      itemBuilder: (context, index) {
        if (index == state.articles.length) {
          return HBButton(
            label: 'Carregar mais',
            isLoading: state.isLoadingMore,
            onPressed: () =>
                ref.read(academyViewModelProvider.notifier).loadNextPage(),
          );
        }
        final article = state.articles[index];
        return KnowledgeArticleCard(
          article: article,
          isFavorite: state.userData.favoriteArticleIds.contains(article.id),
          progress: state.userData.progressByArticleId[article.id],
          onTap: () => context.push(AppRoutes.academyArticlePath(article.id)),
          onFavoritePressed: () => ref
              .read(academyViewModelProvider.notifier)
              .toggleFavorite(article.id),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(academyViewModelProvider.notifier).search(value),
    );
  }

  void _showFilters() {
    final state = ref.read(academyViewModelProvider);
    HBBottomSheet.show<void>(
      context,
      title: 'Filtrar artigos',
      child: KnowledgeFilterSheet(
        catalog: state.catalog!,
        initialFilter: state.filter,
        onApply: ref.read(academyViewModelProvider.notifier).applyFilter,
      ),
    );
  }
}

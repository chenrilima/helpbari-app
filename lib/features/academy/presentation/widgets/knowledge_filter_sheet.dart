import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../../domain/models/models.dart';

class KnowledgeFilterSheet extends StatefulWidget {
  const KnowledgeFilterSheet({
    required this.catalog,
    required this.initialFilter,
    required this.onApply,
    super.key,
  });

  final KnowledgeCatalog catalog;
  final KnowledgeFilter initialFilter;
  final ValueChanged<KnowledgeFilter> onApply;

  @override
  State<KnowledgeFilterSheet> createState() => _KnowledgeFilterSheetState();
}

class _KnowledgeFilterSheetState extends State<KnowledgeFilterSheet> {
  late String? _categoryId = widget.initialFilter.categoryId;
  late final Set<String> _phases = widget.initialFilter.bariatricPhases.toSet();
  late final Set<String> _surgeries = widget.initialFilter.surgeryTypes.toSet();
  late final Set<String> _tags = widget.initialFilter.tags.toSet();
  late final Set<KnowledgeEvidenceLevel> _evidence = widget
      .initialFilter
      .evidenceLevels
      .toSet();
  late bool _favoritesOnly = widget.initialFilter.favoritesOnly;

  @override
  Widget build(BuildContext context) {
    final phases = _distinct((article) => article.bariatricPhases);
    final surgeries = _distinct((article) => article.surgeryTypes);
    final tags = _distinct((article) => article.tags);
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const HBText('Somente favoritos'),
              value: _favoritesOnly,
              onChanged: (value) => setState(() => _favoritesOnly = value),
            ),
            _Section(
              title: 'Categoria',
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
                ...widget.catalog.categories.map(
                  (category) => ChoiceChip(
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
                ),
              ],
            ),
            _Section(
              title: 'Fase bariátrica',
              children: _chips(phases, _phases),
            ),
            _Section(
              title: 'Tipo de cirurgia',
              children: _chips(surgeries, _surgeries),
            ),
            _Section(title: 'Tags', children: _chips(tags, _tags)),
            _Section(
              title: 'Nível de evidência',
              children: KnowledgeEvidenceLevel.values
                  .map((level) {
                    return FilterChip(
                      label: Text(_evidenceLabel(level)),
                      selected: _evidence.contains(level),
                      onSelected: (_) => setState(() {
                        _toggle(_evidence, level);
                      }),
                    );
                  })
                  .toList(growable: false),
            ),
            const HBGap.lg(),
            HBButton(
              label: 'Aplicar filtros',
              onPressed: () {
                widget.onApply(
                  KnowledgeFilter(
                    categoryId: _categoryId,
                    bariatricPhases: _phases,
                    surgeryTypes: _surgeries,
                    tags: _tags,
                    evidenceLevels: _evidence,
                    favoritesOnly: _favoritesOnly,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _chips(List<String> values, Set<String> selected) {
    return values
        .map((value) {
          return FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            onSelected: (_) => setState(() => _toggle(selected, value)),
          );
        })
        .toList(growable: false);
  }

  List<String> _distinct(
    List<String> Function(KnowledgeArticle article) select,
  ) {
    final result = widget.catalog.articles.expand(select).toSet().toList()
      ..sort();
    return result;
  }

  static void _toggle<T>(Set<T> values, T value) {
    if (!values.add(value)) values.remove(value);
  }

  static String _evidenceLabel(KnowledgeEvidenceLevel level) {
    return switch (level) {
      KnowledgeEvidenceLevel.consensus => 'Consenso',
      KnowledgeEvidenceLevel.low => 'Baixa',
      KnowledgeEvidenceLevel.moderate => 'Moderada',
      KnowledgeEvidenceLevel.high => 'Alta',
    };
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText(title, style: Theme.of(context).textTheme.titleSmall),
          const HBGap.sm(),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: children,
          ),
        ],
      ),
    );
  }
}

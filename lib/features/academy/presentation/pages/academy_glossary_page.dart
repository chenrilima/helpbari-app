import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/academy_providers.dart';

class AcademyGlossaryPage extends ConsumerStatefulWidget {
  const AcademyGlossaryPage({super.key});

  @override
  ConsumerState<AcademyGlossaryPage> createState() =>
      _AcademyGlossaryPageState();
}

class _AcademyGlossaryPageState extends ConsumerState<AcademyGlossaryPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(knowledgeCatalogProvider);
    return HBPage(
      scrollable: false,
      appBar: const HBAppBar(title: 'Glossário'),
      children: [
        HBTextField(
          controller: _controller,
          label: 'Buscar termo',
          prefixIcon: Icons.search,
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
        ),
        const HBGap.md(),
        Expanded(
          child: catalog.when(
            loading: () => const HBLoading(message: 'Carregando glossário...'),
            error: (_, _) => HBEmptyState(
              title: 'Glossário indisponível',
              description: 'Não foi possível ler o conteúdo local.',
              actionLabel: 'Tentar novamente',
              onActionPressed: () => ref.invalidate(knowledgeCatalogProvider),
            ),
            data: (value) {
              final items =
                  value.glossary
                      .where((entry) {
                        return entry.term.toLowerCase().contains(_query) ||
                            entry.definition.toLowerCase().contains(_query);
                      })
                      .toList(growable: false)
                    ..sort((a, b) => a.term.compareTo(b.term));
              if (items.isEmpty) {
                return const HBEmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhum termo encontrado',
                  description: 'Tente buscar outra palavra.',
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const HBGap.md(),
                itemBuilder: (context, index) {
                  final entry = items[index];
                  return HBCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HBText(
                          entry.term,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const HBGap.sm(),
                        HBText(entry.definition),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

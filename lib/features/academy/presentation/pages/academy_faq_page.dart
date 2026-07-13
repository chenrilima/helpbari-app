import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/academy_providers.dart';

class AcademyFaqPage extends ConsumerWidget {
  const AcademyFaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(knowledgeCatalogProvider);
    return HBPage(
      appBar: const HBAppBar(title: 'Perguntas frequentes'),
      children: [
        Expanded(
          child: catalog.when(
            loading: () => const HBLoading(message: 'Carregando perguntas...'),
            error: (_, _) => HBEmptyState(
              title: 'Perguntas indisponíveis',
              description: 'Não foi possível ler o conteúdo local.',
              actionLabel: 'Tentar novamente',
              onActionPressed: () => ref.invalidate(knowledgeCatalogProvider),
            ),
            data: (value) => value.faq.isEmpty
                ? const HBEmptyState(
                    title: 'Nenhuma pergunta cadastrada',
                    description: 'Novas perguntas aparecerão aqui.',
                  )
                : ListView.separated(
                    itemCount: value.faq.length,
                    separatorBuilder: (_, _) => const HBGap.md(),
                    itemBuilder: (context, index) {
                      final faq = value.faq[index];
                      return HBCard(
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
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

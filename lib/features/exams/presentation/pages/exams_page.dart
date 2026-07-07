import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/exam_view_model_provider.dart';

class ExamsPage extends ConsumerStatefulWidget {
  const ExamsPage({super.key});

  @override
  ConsumerState<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends ConsumerState<ExamsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(examViewModelProvider.notifier).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examViewModelProvider);

    return HBPage(
      children: [
        HBText('Exam', style: Theme.of(context).textTheme.headlineMedium),
        const HBGap.xl(),
        if (!state.hasItems)
          const HBEmptyState(
            title: 'Nenhum item encontrado',
            description: 'Cadastre o primeiro item para começar.',
            icon: Icons.info_outline,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const HBGap.md(),
            itemBuilder: (_, index) {
              final item = state.items[index];

              return HBCard(child: HBText(item.title));
            },
          ),
      ],
    );
  }
}

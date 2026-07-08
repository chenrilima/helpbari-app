import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/exam_view_model_provider.dart';
import '../widgets/exam_summary_card.dart';
import '../widgets/exam_tile.dart';

class ExamsPage extends ConsumerStatefulWidget {
  const ExamsPage({super.key});

  @override
  ConsumerState<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends ConsumerState<ExamsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(examViewModelProvider.notifier).loadItems(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examViewModelProvider);

    return HBPage(
      appBar: const HBAppBar(title: 'Exames'),
      children: [
        HBText(
          'Acompanhe seus exames realizados.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),

        const HBGap.xl(),

        if (state.latestExam != null)
          ExamSummaryCard(exam: state.latestExam!)
        else
          const HBEmptyState(
            title: 'Nenhum exame cadastrado',
            description: 'Cadastre seu primeiro exame.',
            icon: AppIcons.health,
          ),

        const HBGap.xl(),

        HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),

        const HBGap.md(),

        if (state.hasItems)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const HBGap.md(),
            itemBuilder: (_, index) {
              return ExamTile(exam: state.items[index]);
            },
          ),

        const HBGap.xl(),

        HBButton(
          label: 'Cadastrar exame',
          onPressed: () {
            context.pushAndRefresh(
              AppRoutes.registerExam,
              onRefresh: () {
                return ref.read(examViewModelProvider.notifier).loadItems();
              },
            );
          },
        ),
      ],
    );
  }
}

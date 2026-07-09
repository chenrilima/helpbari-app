import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/vitamin_view_model_provider.dart';
import '../widgets/vitamin_adherence_chart_widget.dart';
import '../widgets/vitamin_tile.dart';

class VitaminsPage extends ConsumerStatefulWidget {
  const VitaminsPage({super.key});

  @override
  ConsumerState<VitaminsPage> createState() => _VitaminsPageState();
}

class _VitaminsPageState extends ConsumerState<VitaminsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(vitaminViewModelProvider.notifier).loadVitamins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vitaminViewModelProvider);

    return HBPage(
      appBar: const HBAppBar(title: 'Cadastro de vitaminas'),
      children: [
        HBText(
          'Acompanhe seus suplementos diários.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const HBGap.xl(),
        const VitaminAdherenceChartWidget(),
        const HBGap.xl(),
        if (!state.hasVitamins)
          const HBEmptyState(
            title: 'Nenhuma vitamina cadastrada',
            description:
                'Cadastre seus suplementos para acompanhar sua rotina diária.',
            icon: AppIcons.vitamin,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.vitamins.length,
            separatorBuilder: (_, _) => const HBGap.md(),
            itemBuilder: (_, index) {
              final vitamin = state.vitamins[index];

              return VitaminTile(
                vitamin: vitamin,
                onTaken: () {
                  ref
                      .read(vitaminViewModelProvider.notifier)
                      .markAsTaken(vitamin.id);
                },
                onSkipped: () {
                  ref
                      .read(vitaminViewModelProvider.notifier)
                      .markAsSkipped(vitamin.id);
                },
              );
            },
          ),
        const HBGap.xl(),
        HBButton(
          label: 'Cadastrar vitamina',
          onPressed: () {
            context.pushAndRefresh(
              AppRoutes.registerVitamin,
              onRefresh: () {
                return ref
                    .read(vitaminViewModelProvider.notifier)
                    .loadVitamins();
              },
            );
          },
        ),
      ],
    );
  }
}

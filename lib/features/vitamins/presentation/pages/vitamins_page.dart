import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  Future<void> _delete(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir vitamina?',
      message: 'O cadastro e o histórico desta vitamina serão removidos.',
    );
    if (confirmed != true || !mounted) return;
    final ok = await ref
        .read(vitaminViewModelProvider.notifier)
        .deleteVitamin(id);
    if (!mounted) return;
    if (ok) HBSnackBar.success(context, message: 'Vitamina excluída.');
  }

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
        if (state.isLoading && !state.hasVitamins)
          const Center(child: CircularProgressIndicator())
        else if (state.errorMessage != null && !state.hasVitamins)
          HBEmptyState(
            title: 'Não foi possível carregar',
            description: state.errorMessage!,
            icon: AppIcons.vitamin,
          )
        else if (!state.hasVitamins)
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
                status: state.statusFor(vitamin.id),
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
                onEdit: () async {
                  await context.push<bool>(
                    AppRoutes.registerVitamin,
                    extra: vitamin,
                  );
                  await ref
                      .read(vitaminViewModelProvider.notifier)
                      .loadVitamins();
                },
                onDelete: () => _delete(vitamin.id),
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

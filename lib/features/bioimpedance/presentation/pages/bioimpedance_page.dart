import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/bioimpedance_record.dart';
import '../providers/bioimpedance_view_model_provider.dart';
import '../widgets/bioimpedance_tile.dart';

class BioimpedancePage extends ConsumerStatefulWidget {
  const BioimpedancePage({super.key});

  @override
  ConsumerState<BioimpedancePage> createState() => _BioimpedancePageState();
}

class _BioimpedancePageState extends ConsumerState<BioimpedancePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bioimpedanceViewModelProvider.notifier).loadHistory(),
    );
  }

  Future<void> _openRegister([BioimpedanceRecord? record]) async {
    final changed = await context.push<bool>(
      AppRoutes.registerBioimpedance,
      extra: record,
    );
    if (changed == true) {
      await ref.read(bioimpedanceViewModelProvider.notifier).loadHistory();
    }
  }

  Future<void> _openDetails(BioimpedanceRecord record) async {
    await context.push<void>(AppRoutes.bioimpedanceDetails, extra: record);
    await ref.read(bioimpedanceViewModelProvider.notifier).loadHistory();
  }

  Future<void> _delete(BioimpedanceRecord record) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir avaliação?',
      message: 'A exclusão será lógica e sincronizada quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(bioimpedanceViewModelProvider.notifier)
        .deleteRecord(record);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Avaliação excluída com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(bioimpedanceViewModelProvider).errorMessage ??
            'Não foi possível excluir a avaliação.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bioimpedanceViewModelProvider);
    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Carregando bioimpedâncias...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Bioimpedância',
          subtitle: 'Acompanhe suas avaliações corporais',
        ),
        children: [
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar as avaliações',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: () => ref
                  .read(bioimpedanceViewModelProvider.notifier)
                  .loadHistory(),
            )
          else if (!state.hasItems)
            HBEmptyState(
              title: 'Nenhuma avaliação registrada',
              description:
                  'Cadastre manualmente ou importe um laudo de bioimpedância.',
              icon: AppIcons.health,
              actionLabel: 'Cadastrar avaliação',
              onActionPressed: _openRegister,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final record = state.items[index];
                return Column(
                  children: [
                    BioimpedanceTile(
                      record: record,
                      onTap: () => _openDetails(record),
                    ),
                    const HBGap.sm(),
                    Row(
                      children: [
                        Expanded(
                          child: HBButton(
                            label: 'Editar',
                            onPressed: () => _openRegister(record),
                          ),
                        ),
                        const HBGap.md(),
                        Expanded(
                          child: HBButton(
                            label: 'Excluir',
                            onPressed: () => _delete(record),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          const HBGap.xl(),
          HBButton(label: 'Nova avaliação', onPressed: () => _openRegister()),
        ],
      ),
    );
  }
}

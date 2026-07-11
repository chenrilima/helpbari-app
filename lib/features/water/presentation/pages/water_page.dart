import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../providers/water_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../widgets/water_chart_widget.dart';
import '../widgets/water_progress_card.dart';
import '../widgets/water_summary_card.dart';
import '../widgets/water_tile.dart';

class WaterPage extends ConsumerStatefulWidget {
  const WaterPage({super.key});

  @override
  ConsumerState<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends ConsumerState<WaterPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    await ref.read(waterViewModelProvider.notifier).loadHistory();
  }

  Future<void> _openRegisterWater() async {
    await context.pushAndRefresh(
      AppRoutes.registerWater,
      onRefresh: _loadHistory,
    );
  }

  Future<void> _editWater(WaterRecord record) async {
    final changed = await context.push<bool>(
      AppRoutes.registerWater,
      extra: record,
    );
    if (changed == true) await _loadHistory();
  }

  Future<void> _deleteWater(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir registro?',
      message:
          'O registro será removido do histórico e sincronizado quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(waterViewModelProvider.notifier)
        .deleteWater(id);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Registro excluído com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(waterViewModelProvider).errorMessage ??
            'Não foi possível excluir o registro.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterViewModelProvider);
    final goalMl = ref.watch(dailyWaterGoalProvider).value ?? 2000;

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Atualizando hidratação...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Água',
          subtitle: 'Acompanhe sua hidratação',
        ),
        children: [
          WaterSummaryCard(totalToday: state.formattedToday),
          const HBGap.lg(),
          WaterProgressCard(currentMl: state.totalTodayInMl, goalMl: goalMl),
          const HBGap.xl(),
          const WaterChartWidget(),
          const HBGap.xl(),
          HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),
          const HBGap.md(),
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar os registros',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _loadHistory,
            )
          else if (!state.hasRecords)
            const HBEmptyState(
              title: 'Nenhum registro encontrado',
              description: 'Registre sua primeira ingestão de água.',
              icon: AppIcons.water,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.records.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final record = state.records[index];
                return WaterTile(
                  record: record,
                  onEdit: () => _editWater(record),
                  onDelete: () => _deleteWater(record.id),
                );
              },
            ),
          const HBGap.xl(),
          HBButton(label: 'Registrar água', onPressed: _openRegisterWater),
        ],
      ),
    );
  }
}

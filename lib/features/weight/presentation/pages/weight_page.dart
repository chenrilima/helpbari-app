import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/weight_view_model_provider.dart';
import '../widgets/weight_chart_widget.dart';
import '../widgets/weight_summary_card.dart';
import '../widgets/weight_tile.dart';
import '../../domain/entities/entities.dart';

class WeightPage extends ConsumerStatefulWidget {
  const WeightPage({super.key});

  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends ConsumerState<WeightPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    await ref.read(weightViewModelProvider.notifier).loadHistory();
  }

  Future<void> _openRegisterWeight() async {
    await context.pushAndRefresh<bool>(
      AppRoutes.registerWeight,
      onRefresh: _loadHistory,
      shouldRefresh: (created) => created == true,
    );
  }

  Future<void> _editWeight(WeightRecord record) async {
    final changed = await context.push<bool>(
      AppRoutes.registerWeight,
      extra: record,
    );
    if (changed == true) await _loadHistory();
  }

  Future<void> _deleteWeight(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir registro?',
      message:
          'O registro será removido do histórico e sincronizado quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(weightViewModelProvider.notifier)
        .deleteWeight(id);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Registro excluído com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(weightViewModelProvider).errorMessage ??
            'Não foi possível excluir o registro.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightViewModelProvider);

    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Atualizando peso...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Peso',
          subtitle: 'Acompanhe sua evolução',
        ),
        children: [
          if (state.latestRecord != null) ...[
            WeightSummaryCard(record: state.latestRecord!),
            const HBGap.lg(),
          ],
          const WeightChartWidget(),
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
              title: 'Nenhum peso registrado',
              description:
                  'Registre seu primeiro peso para acompanhar sua evolução.',
              icon: AppIcons.weight,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.records.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final record = state.records[index];
                return WeightTile(
                  record: record,
                  onEdit: () => _editWeight(record),
                  onDelete: () => _deleteWeight(record.id),
                );
              },
            ),
          const HBGap.xl(),
          HBButton(
            label: 'Registrar novo peso',
            onPressed: _openRegisterWeight,
          ),
        ],
      ),
    );
  }
}

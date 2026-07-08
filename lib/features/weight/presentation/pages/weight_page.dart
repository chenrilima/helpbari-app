import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/weight_view_model_provider.dart';
import '../widgets/weight_chart_widget.dart';
import '../widgets/weight_summary_card.dart';
import '../widgets/weight_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightViewModelProvider);

    return HBPage(
      appBar: const HBAppBar(title: 'Peso', subtitle: 'Acompanhe sua evolução'),
      children: [
        if (state.latestRecord != null) ...[
          WeightSummaryCard(record: state.latestRecord!),
          const HBGap.lg(),
        ],
        const WeightChartWidget(),
        const HBGap.xl(),
        HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),
        const HBGap.md(),
        if (!state.hasRecords)
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
              return WeightTile(record: state.records[index]);
            },
          ),
        const HBGap.xl(),
        HBButton(label: 'Registrar novo peso', onPressed: _openRegisterWeight),
      ],
    );
  }
}

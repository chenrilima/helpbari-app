import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
import '../providers/water_view_model_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waterViewModelProvider);

    return HBPage(
      appBar: const HBAppBar(
        title: 'Água',
        subtitle: 'Acompanhe sua hidratação',
      ),
      children: [
        WaterSummaryCard(totalToday: state.formattedToday),
        const HBGap.lg(),
        WaterProgressCard(currentMl: state.totalTodayInMl),
        const HBGap.xl(),
        const WaterChartWidget(),
        const HBGap.xl(),
        HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),
        const HBGap.md(),
        if (!state.hasRecords)
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
              return WaterTile(record: state.records[index]);
            },
          ),
        const HBGap.xl(),
        HBButton(label: 'Registrar água', onPressed: _openRegisterWater),
      ],
    );
  }
}

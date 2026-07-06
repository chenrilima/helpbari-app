import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
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

    Future.microtask(() {
      ref.read(weightViewModelProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightViewModelProvider);

    return HBPage(
      children: [
        if (state.latestRecord != null) ...[
          WeightSummaryCard(record: state.latestRecord!),
          const HBGap.lg(),
        ],

        const WeightChartWidget(),

        const HBGap.xl(),

        HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),

        const HBGap.md(),

        if (state.records.isEmpty)
          const HBEmptyState(
            title: 'Nenhum peso registrado',
            description:
                'Registre seu primeiro peso para acompanhar sua evolução.',
            icon: Icons.monitor_weight_outlined,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.records.length,
            separatorBuilder: (_, __) => const HBGap.md(),
            itemBuilder: (_, index) {
              return WeightTile(record: state.records[index]);
            },
          ),

        const HBGap.xl(),

        HBButton(
          label: 'Registrar novo peso',
          onPressed: () {
            context.push(AppRoutes.registerWeight);
          },
        ),
      ],
    );
  }
}

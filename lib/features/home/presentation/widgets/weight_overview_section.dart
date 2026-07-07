import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../weight/domain/entities/entities.dart';
import '../../../weight/presentation/widgets/weight_chart_widget.dart';
import '../../../weight/presentation/widgets/weight_summary_card.dart';
import 'home_section.dart';

class WeightOverviewSection extends StatelessWidget {
  const WeightOverviewSection({
    required this.latestRecord,
    required this.hasRecords,
    this.progressMessage,
    super.key,
  });

  final WeightRecord? latestRecord;
  final bool hasRecords;
  final String? progressMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeSection(
          title: 'Sua evolução',
          child: latestRecord != null
              ? WeightSummaryCard(
                  record: latestRecord!,
                  description: progressMessage,
                  onTap: () => context.push(AppRoutes.weight),
                )
              : const HBEmptyState(
                  title: 'Nenhum peso registrado',
                  description:
                      'Registre seu primeiro peso para acompanhar sua evolução.',
                  icon: AppIcons.weight,
                ),
        ),
        if (hasRecords) ...[
          const HBGap.xl(),
          const HomeSection(title: 'Evolução', child: WeightChartWidget()),
        ],
      ],
    );
  }
}

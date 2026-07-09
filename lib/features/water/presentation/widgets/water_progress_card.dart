import 'package:flutter/material.dart';

import '../../../../core/formatters/app_number_formatter.dart';
import '../../../../core/formatters/app_water_formatter.dart';
import '../../../../design_system/design_system.dart';

class WaterProgressCard extends StatelessWidget {
  const WaterProgressCard({
    required this.currentMl,
    this.goalMl = 2000,
    super.key,
  });

  final int currentMl;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final progress = (currentMl / goalMl).clamp(0.0, 1.0);

    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText('Meta diária', style: Theme.of(context).textTheme.titleMedium),

          const HBGap.md(),

          HBText(
            AppWaterFormatter.goal(currentMl: currentMl, goalMl: goalMl),
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const HBGap.md(),

          LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(AppRadius.full),
            minHeight: 10,
          ),

          const HBGap.sm(),

          Align(
            alignment: Alignment.centerRight,
            child: HBText(
              AppNumberFormatter.percentage(progress * 100),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

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
            '${(currentMl / 1000).toStringAsFixed(1)} L de ${(goalMl / 1000).toStringAsFixed(1)} L',
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
              '${(progress * 100).round()}%',
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

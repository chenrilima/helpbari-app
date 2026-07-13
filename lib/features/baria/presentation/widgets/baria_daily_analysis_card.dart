import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';

class BariaDailyAnalysisCard extends StatelessWidget {
  const BariaDailyAnalysisCard({required this.insight, super.key});

  final BariaInsight insight;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: AppSizes.iconMd),
              const HBGap.horizontal(AppSpacing.md),
              Expanded(
                child: HBText(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const HBGap.md(),
          HBText(
            insight.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (insight.healthScoreImprovement != null) ...[
            const HBGap.md(),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: HBText(
                '📈 Potencial de melhora: +${insight.healthScoreImprovement!.toStringAsFixed(1)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

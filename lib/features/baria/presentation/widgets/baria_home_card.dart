import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';
import 'baria_sheet.dart';

class BariaHomeCard extends StatelessWidget {
  const BariaHomeCard({required this.insight, super.key});

  final BariaInsight insight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir BarIA. ${insight.message}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => BariaSheet.show(context),
        child: HBCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.primary,
                  size: AppSizes.iconLg,
                ),
              ),
              const HBGap.horizontal(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HBText(
                      'BarIA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const HBGap.xs(),
                    HBText(
                      insight.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const HBGap.horizontal(AppSpacing.md),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconSm,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

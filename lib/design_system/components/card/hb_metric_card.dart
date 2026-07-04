import 'package:flutter/material.dart';

import '../../primitives/primitives.dart';
import '../../theme/theme.dart';

class HBMetricCard extends StatelessWidget {
  const HBMetricCard({
    required this.title,
    required this.value,
    super.key,
    this.description,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.trailing,
    this.badge,
    this.onTap,
  });

  final String title;
  final String value;
  final String? description;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Widget? trailing;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: AppSizes.avatarMd,
              height: AppSizes.avatarMd,
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: HBIcon(icon!, color: iconColor ?? AppColors.primary),
            ),
            const HBGap.horizontal(AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(title, style: Theme.of(context).textTheme.bodyMedium),
                const HBGap.xs(),
                HBText(value, style: Theme.of(context).textTheme.titleLarge),
                if (description != null) ...[
                  const HBGap.xs(),
                  HBText(
                    description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (badge != null) ...[const HBGap.sm(), badge!],
              ],
            ),
          ),
          if (trailing != null) ...[
            const HBGap.horizontal(AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: content,
    );
  }
}

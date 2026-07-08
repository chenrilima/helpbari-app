import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBEmptyState extends StatelessWidget {
  const HBEmptyState({
    required this.title,
    required this.description,
    super.key,
    this.icon = Icons.info_outline,
    this.actionLabel,
    this.onActionPressed,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.avatarLg,
            height: AppSizes.avatarLg,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: AppColors.primary, size: AppSizes.iconLg),
          ),
          const HBGap.lg(),
          HBText(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const HBGap.sm(),
          HBText(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onActionPressed != null) ...[
            const HBGap.lg(),
            HBButton(label: actionLabel!, onPressed: onActionPressed),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Center(child: content);
    }

    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

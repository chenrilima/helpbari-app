import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class OnboardingOptionTile extends StatelessWidget {
  const OnboardingOptionTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      backgroundColor: isSelected ? AppColors.primaryLight : AppColors.surface,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryDark : AppColors.info,
          ),
          const HBGap.horizontal(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(label, style: Theme.of(context).textTheme.titleSmall),
                const HBGap.xs(),
                HBText(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const HBGap.horizontal(AppSpacing.sm),
          Icon(
            isSelected
                ? Icons.check_circle
                : Icons.radio_button_unchecked_outlined,
            color: isSelected ? AppColors.primary : AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}

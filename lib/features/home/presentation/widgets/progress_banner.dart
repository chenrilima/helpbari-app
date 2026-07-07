import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ProgressBanner extends StatelessWidget {
  const ProgressBanner({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.favorite_outline, color: AppColors.primary),
          ),

          const HBGap.md(),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(title, style: Theme.of(context).textTheme.titleMedium),

                const HBGap.xs(),

                HBText(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

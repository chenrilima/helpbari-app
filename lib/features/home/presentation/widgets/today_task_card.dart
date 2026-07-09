import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),

          const HBGap.md(),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(title, style: Theme.of(context).textTheme.titleMedium),

                const HBGap.xs(),

                HBText(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const ExcludeSemantics(child: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

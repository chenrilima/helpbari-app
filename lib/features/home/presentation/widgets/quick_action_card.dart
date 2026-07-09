import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
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
    return SizedBox(
      width: 140,
      child: HBCard(
        onTap: onTap,
        semanticLabel: '$title. $subtitle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),

            const HBGap.md(),

            HBText(title, style: Theme.of(context).textTheme.titleMedium),

            const HBGap.xs(),

            HBText(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

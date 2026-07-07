import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class VitaminTile extends StatelessWidget {
  const VitaminTile({
    required this.vitamin,
    required this.onTaken,
    required this.onSkipped,
    super.key,
  });

  final Vitamin vitamin;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const Icon(AppIcons.vitamin, color: AppColors.primary),
          const HBGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  vitamin.formattedName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const HBGap.xs(),
                HBText(
                  '${vitamin.formattedTime} • ${vitamin.status.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (vitamin.isPending) ...[
            IconButton(onPressed: onSkipped, icon: const Icon(Icons.close)),
            IconButton(onPressed: onTaken, icon: const Icon(Icons.check)),
          ],
        ],
      ),
    );
  }
}

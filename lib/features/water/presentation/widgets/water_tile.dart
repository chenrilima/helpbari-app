import 'package:flutter/material.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class WaterTile extends StatelessWidget {
  const WaterTile({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final WaterRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const Icon(AppIcons.water, color: AppColors.primary),

          const HBGap.md(),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  record.formattedAmount,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const HBGap.xs(),
                HBText(
                  AppDateFormatter.shortWithTime(record.recordedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar registro',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir registro',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

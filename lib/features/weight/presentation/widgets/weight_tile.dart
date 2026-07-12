import 'package:flutter/material.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class WeightTile extends StatelessWidget {
  const WeightTile({
    required this.record,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final WeightRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_outlined),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  record.formattedWeight,
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                HBText(
                  AppDateFormatter.shortWithTime(record.recordedAt.value),
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                if (record.hasNotes) ...[
                  const SizedBox(height: 8),

                  HBText(record.notes!.value),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Editar registro',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Excluir registro',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class MealTile extends StatelessWidget {
  const MealTile({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Meal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const Icon(Icons.restaurant_outlined, color: AppColors.primary),
          const HBGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  meal.formattedName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const HBGap.xs(),
                HBText(
                  '${meal.formattedType} • ${meal.formattedDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const HBGap.xs(),
                HBText(
                  meal.formattedProtein,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar refeição',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir refeição',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

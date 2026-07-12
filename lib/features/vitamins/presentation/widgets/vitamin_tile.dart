import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/vitamin_status.dart';

class VitaminTile extends StatelessWidget {
  const VitaminTile({
    required this.vitamin,
    required this.onTaken,
    required this.onSkipped,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Vitamin vitamin;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VitaminStatus status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(AppIcons.vitamin, color: AppColors.primary),
          ),
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
                  '${vitamin.formattedTime} • ${status.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (status == VitaminStatus.pending) ...[
            IconButton(
              tooltip: 'Pular vitamina',
              onPressed: onSkipped,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Marcar vitamina como tomada',
              onPressed: onTaken,
              icon: const Icon(Icons.check),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

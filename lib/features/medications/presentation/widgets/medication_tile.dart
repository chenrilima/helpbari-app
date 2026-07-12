import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/medication_status.dart';

class MedicationTile extends StatelessWidget {
  const MedicationTile({
    required this.medication,
    required this.onTaken,
    required this.onSkipped,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Medication medication;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final MedicationStatus status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(Icons.medication_outlined, color: AppColors.primary),
          ),
          const HBGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  medication.formattedName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const HBGap.xs(),
                HBText(
                  '${medication.formattedTime} • ${status.label}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (medication.dosage != null &&
                    medication.dosage!.isNotEmpty) ...[
                  const HBGap.xs(),
                  HBText(
                    medication.dosage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (status == MedicationStatus.pending) ...[
            IconButton(
              tooltip: 'Pular medicamento',
              onPressed: onSkipped,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Marcar medicamento como tomado',
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

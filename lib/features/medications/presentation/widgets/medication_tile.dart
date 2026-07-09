import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class MedicationTile extends StatelessWidget {
  const MedicationTile({
    required this.medication,
    required this.onTaken,
    required this.onSkipped,
    super.key,
  });

  final Medication medication;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;

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
                  '${medication.formattedTime} • ${medication.statusDescription}',
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
          if (medication.isPending) ...[
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
        ],
      ),
    );
  }
}

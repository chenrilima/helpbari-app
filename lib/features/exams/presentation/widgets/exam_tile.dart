import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ExamTile extends StatelessWidget {
  const ExamTile({
    required this.exam,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Exam exam;
  final VoidCallback onView, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText(
            exam.formattedName,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const HBGap.xs(),

          HBText(
            exam.formattedDate,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          if (exam.laboratory != null && exam.laboratory!.isNotEmpty) ...[
            const HBGap.xs(),

            HBText(
              exam.laboratory!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          if (exam.hasAttachment) ...[
            const HBGap.sm(),

            const Row(
              children: [
                Icon(Icons.attach_file, size: AppSizes.iconSm),
                HBGap.horizontal(AppSpacing.xs),
                HBText('Resultado anexado'),
              ],
            ),
          ],
          const HBGap.sm(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Detalhes',
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

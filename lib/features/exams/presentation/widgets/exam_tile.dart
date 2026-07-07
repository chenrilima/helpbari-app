import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ExamTile extends StatelessWidget {
  const ExamTile({required this.exam, super.key});

  final Exam exam;

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
                Icon(Icons.attach_file, size: 18),
                SizedBox(width: 4),
                HBText('Resultado anexado'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

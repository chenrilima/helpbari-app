import 'package:flutter/material.dart';

import '../../../../core/formatters/formatters.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({required this.report, super.key});

  final GeneratedMedicalReport report;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HBIcon(Icons.picture_as_pdf_outlined),
              const HBGap.horizontal(AppSpacing.sm),
              Expanded(
                child: HBText(
                  report.fileName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const HBGap.sm(),
          HBText(
            'Gerado em ${AppDateFormatter.shortWithTime(report.generatedAt)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (report.savedPath != null) ...[
            const HBGap.xs(),
            HBText(
              'Salvo em ${report.savedPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

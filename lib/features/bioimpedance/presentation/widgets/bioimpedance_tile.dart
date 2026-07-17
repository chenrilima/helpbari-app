import 'package:flutter/material.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/bioimpedance_record.dart';

class BioimpedanceTile extends StatelessWidget {
  const BioimpedanceTile({
    required this.record,
    required this.onTap,
    super.key,
  });

  final BioimpedanceRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final measurements = <String>[
      if (record.weightKg != null) '${record.weightKg!.toStringAsFixed(1)} kg',
      if (record.bodyFatPercentage != null)
        '${record.bodyFatPercentage!.toStringAsFixed(1)} % gordura',
      if (record.bodyFatMassKg != null)
        '${record.bodyFatMassKg!.toStringAsFixed(1)} kg gordura',
      if (record.muscleMassKg != null)
        '${record.muscleMassKg!.toStringAsFixed(1)} kg músculo',
    ];

    return HBCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText(
            AppDateFormatter.shortWithTime(record.measuredAt),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const HBGap.sm(),
          HBText(
            measurements.isEmpty
                ? 'Medidas complementares registradas.'
                : measurements.join(' • '),
          ),
          const HBGap.sm(),
          HBText(
            record.source == BioimpedanceRecordSource.document
                ? 'Origem documental'
                : 'Origem manual',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

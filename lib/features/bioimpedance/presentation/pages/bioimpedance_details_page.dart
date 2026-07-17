import 'package:flutter/material.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/bioimpedance_record.dart';

class BioimpedanceDetailsPage extends StatelessWidget {
  const BioimpedanceDetailsPage({required this.record, super.key});

  final BioimpedanceRecord record;

  @override
  Widget build(BuildContext context) {
    final fields = <({String label, String value})>[
      (
        label: 'Data da avaliação',
        value: AppDateFormatter.shortWithTime(record.measuredAt),
      ),
      if (record.weightKg != null)
        (label: 'Peso', value: '${record.weightKg!.toStringAsFixed(1)} kg'),
      if (record.muscleMassKg != null)
        (
          label: 'Massa muscular',
          value: '${record.muscleMassKg!.toStringAsFixed(1)} kg',
        ),
      if (record.bodyFatMassKg != null)
        (
          label: 'Massa de gordura',
          value: '${record.bodyFatMassKg!.toStringAsFixed(1)} kg',
        ),
      if (record.bodyWaterPercentage != null)
        (
          label: 'Água corporal',
          value: '${record.bodyWaterPercentage!.toStringAsFixed(1)} %',
        ),
      if (record.bodyFatPercentage != null)
        (
          label: 'Percentual de gordura',
          value: '${record.bodyFatPercentage!.toStringAsFixed(1)} %',
        ),
      if (record.bmi != null)
        (label: 'IMC', value: record.bmi!.toStringAsFixed(1)),
      if (record.deviceName?.isNotEmpty ?? false)
        (label: 'Equipamento', value: record.deviceName!),
      if (record.clinicName?.isNotEmpty ?? false)
        (label: 'Clínica', value: record.clinicName!),
      if (record.professionalName?.isNotEmpty ?? false)
        (label: 'Profissional', value: record.professionalName!),
      if (record.notes?.isNotEmpty ?? false)
        (label: 'Observações', value: record.notes!),
      (
        label: 'Origem',
        value: record.source == BioimpedanceRecordSource.document
            ? 'Documental'
            : 'Manual',
      ),
      if (record.sourceDocumentId?.isNotEmpty ?? false)
        (label: 'Documento vinculado', value: 'ID ${record.sourceDocumentId}'),
    ];

    return HBPage(
      appBar: const HBAppBar(title: 'Detalhes da bioimpedância'),
      children: [
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in fields) ...[
                HBText(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const HBGap.xs(),
                HBText(field.value),
                const HBGap.md(),
              ],
              if (record.additionalMetrics.isNotEmpty) ...[
                HBText(
                  'Métricas adicionais',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const HBGap.md(),
                for (final metric in record.additionalMetrics.values) ...[
                  HBText('${metric.label}: ${metric.originalValue}'),
                  const HBGap.sm(),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

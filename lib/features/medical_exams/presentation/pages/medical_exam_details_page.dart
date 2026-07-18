import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class MedicalExamDetailsPage extends ConsumerWidget {
  const MedicalExamDetailsPage({required this.exam, super.key});

  final MedicalExam exam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeResults =
        exam.results.where((item) => item.deletedAt == null).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return HBPage(
      appBar: const HBAppBar(
        title: 'Detalhes do exame',
        subtitle: 'Confira os resultados registrados',
      ),
      children: [
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HBText(
                exam.title?.trim().isNotEmpty == true
                    ? exam.title!
                    : 'Exame laboratorial',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const HBGap.md(),
              HBText('Data: ${AppDateFormatter.short(exam.performedAt)}'),
              if ((exam.laboratoryName?.trim().isNotEmpty ?? false))
                HBText('Laboratório: ${exam.laboratoryName}'),
              if ((exam.professionalName?.trim().isNotEmpty ?? false))
                HBText('Profissional: ${exam.professionalName}'),
              if ((exam.legacyAttachmentPath?.trim().isNotEmpty ?? false))
                HBText('Anexo legado: ${exam.legacyAttachmentPath}'),
              if ((exam.notes?.trim().isNotEmpty ?? false)) ...[
                const HBGap.md(),
                HBText(exam.notes!),
              ],
            ],
          ),
        ),
        const HBGap.lg(),
        if (activeResults.isEmpty)
          const HBEmptyState(
            title: 'Nenhum marcador registrado',
            description: 'Adicione resultados para acompanhar este exame.',
            icon: Icons.science_outlined,
          )
        else
          ...activeResults.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HBText(
                      result.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const HBGap.sm(),
                    HBText(_valueLabel(result)),
                    if ((result.referenceRangeText?.trim().isNotEmpty ?? false))
                      HBText('Referência: ${result.referenceRangeText}'),
                    if ((result.status?.trim().isNotEmpty ?? false))
                      HBText('Status: ${result.status}'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _valueLabel(MedicalExamResult result) {
    if (result.numericValue != null) {
      final suffix = result.normalizedUnit?.trim().isNotEmpty == true
          ? ' ${result.normalizedUnit}'
          : result.unit?.trim().isNotEmpty == true
          ? ' ${result.unit}'
          : '';
      return 'Valor: ${result.numericValue}$suffix';
    }
    if ((result.textValue?.trim().isNotEmpty ?? false)) {
      return 'Valor: ${result.textValue}';
    }
    if ((result.qualitativeValue?.trim().isNotEmpty ?? false)) {
      return 'Valor: ${result.qualitativeValue}';
    }
    if (result.booleanValue != null) {
      return 'Valor: ${result.booleanValue! ? 'Sim' : 'Não'}';
    }
    return 'Valor não informado';
  }
}

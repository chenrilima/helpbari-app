import 'package:flutter/material.dart';

import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class MedicalConsultationDetailsPage extends StatelessWidget {
  const MedicalConsultationDetailsPage({required this.consultation, super.key});

  final MedicalConsultation consultation;

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Detalhes da consulta',
        subtitle: 'Revise orientações e próximos passos',
      ),
      children: [
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HBText(
                consultation.title?.trim().isNotEmpty == true
                    ? consultation.title!
                    : 'Consulta clínica',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const HBGap.sm(),
              HBText(
                'Data: ${AppDateFormatter.shortWithTime(consultation.consultationAt)}',
              ),
              if (consultation.professionalName?.trim().isNotEmpty == true)
                HBText('Profissional: ${consultation.professionalName}'),
              if (consultation.specialty?.trim().isNotEmpty == true)
                HBText('Especialidade: ${consultation.specialty}'),
              if (consultation.clinicName?.trim().isNotEmpty == true)
                HBText('Clínica: ${consultation.clinicName}'),
              if (consultation.location?.trim().isNotEmpty == true)
                HBText('Local: ${consultation.location}'),
            ],
          ),
        ),
        const HBGap.lg(),
        _Section(title: 'Motivo', value: consultation.reason),
        _Section(title: 'Sintomas', value: consultation.symptoms),
        _Section(
          title: 'Orientações profissionais',
          value: consultation.professionalGuidance,
        ),
        _Section(
          title: 'Orientações alimentares',
          value: consultation.dietaryGuidance,
        ),
        _Section(
          title: 'Atividade física',
          value: consultation.physicalActivityGuidance,
        ),
        _Section(
          title: 'Suplementação',
          value: consultation.supplementGuidance,
        ),
        _Section(title: 'Medicação', value: consultation.medicationGuidance),
        _Section(
          title: 'Exames solicitados',
          value: consultation.requestedExamsNotes,
        ),
        _Section(title: 'Próximos passos', value: consultation.followUpNotes),
        _Section(title: 'Observações gerais', value: consultation.generalNotes),
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HBText('Itens relacionados'),
              const HBGap.sm(),
              HBText(
                '${consultation.relatedExamIds.length} exame(s) relacionado(s)',
              ),
              HBText(
                '${consultation.relatedBodyCompositionIds.length} bioimpedância(s) relacionada(s)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value?.trim().isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HBCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HBText(title, style: Theme.of(context).textTheme.titleMedium),
            const HBGap.sm(),
            HBText(value!),
          ],
        ),
      ),
    );
  }
}

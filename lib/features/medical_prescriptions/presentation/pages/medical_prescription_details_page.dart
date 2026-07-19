import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';

class MedicalPrescriptionDetailsPage extends ConsumerWidget {
  const MedicalPrescriptionDetailsPage({required this.prescription, super.key});
  final MedicalPrescription prescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HBPage(
    appBar: const HBAppBar(title: 'Detalhes da prescrição'),
    children: [
      HBCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HBText(
              'Data: ${AppDateFormatter.short(prescription.prescribedAt)}',
            ),
            if (prescription.professionalName != null)
              HBText('Profissional: ${prescription.professionalName}'),
            if (prescription.professionalSpecialty != null)
              HBText('Especialidade: ${prescription.professionalSpecialty}'),
            if (prescription.professionalRegistration != null)
              HBText('Registro: ${prescription.professionalRegistration}'),
            if (prescription.sourceDocumentId != null)
              const HBText('Documento original preservado e vinculado'),
          ],
        ),
      ),
      const HBGap.lg(),
      for (final item in prescription.activeItems) ...[
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HBText(item.name, style: Theme.of(context).textTheme.titleSmall),
              HBText('Tipo: ${item.itemType.name}'),
              if (item.dosageValue != null)
                HBText('Dose: ${item.dosageValue} ${item.dosageUnit ?? ''}'),
              if (item.instructions != null) HBText(item.instructions!),
              if (item.asNeeded) const HBText('Uso se necessário'),
              if (item.isLinked) const HBText('Adicionado à rotina'),
            ],
          ),
        ),
        const HBGap.sm(),
      ],
      HBButton(
        label: 'Editar',
        onPressed: () => context.push(
          AppRoutes.editPrescriptionPath(prescription.id),
          extra: prescription,
        ),
      ),
      const HBGap.sm(),
      HBButton(
        label: 'Adicionar itens à rotina',
        onPressed: () => context.push(
          AppRoutes.addPrescriptionToRoutinePath(prescription.id),
          extra: prescription,
        ),
      ),
      const HBGap.sm(),
      HBButton(
        label: 'Excluir prescrição',
        onPressed: () async {
          final confirmed = await HBDialog.confirm(
            context,
            title: 'Excluir prescrição?',
            message: 'As rotinas já criadas não serão excluídas.',
            confirmLabel: 'Excluir',
          );
          if (confirmed != true) return;
          final success = await ref
              .read(medicalPrescriptionViewModelProvider.notifier)
              .delete(prescription.id);
          if (success && context.mounted) context.go(AppRoutes.prescriptions);
        },
      ),
    ],
  );
}

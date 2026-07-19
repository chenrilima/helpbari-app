import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';

class MedicalPrescriptionsPage extends ConsumerStatefulWidget {
  const MedicalPrescriptionsPage({super.key});
  @override
  ConsumerState<MedicalPrescriptionsPage> createState() =>
      _MedicalPrescriptionsPageState();
}

class _MedicalPrescriptionsPageState
    extends ConsumerState<MedicalPrescriptionsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(medicalPrescriptionViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalPrescriptionViewModelProvider);
    return HBPage(
      appBar: const HBAppBar(
        title: 'Prescrições',
        subtitle: 'Histórico de orientações clínicas',
      ),
      children: [
        if (state.isLoading && state.items.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.items.isEmpty)
          HBEmptyState(
            title: 'Nenhuma prescrição cadastrada',
            description: 'Cadastre manualmente ou importe uma receita.',
            actionLabel: 'Cadastrar prescrição',
            onActionPressed: () => context.push(AppRoutes.newPrescription),
          )
        else
          for (final prescription in state.items) ...[
            _PrescriptionCard(
              prescription: prescription,
              onTap: () => context.push(
                AppRoutes.prescriptionDetailsPath(prescription.id),
                extra: prescription,
              ),
            ),
            const HBGap.md(),
          ],
        const HBGap.lg(),
        HBButton(
          label: 'Cadastrar prescrição',
          onPressed: () => context.push(AppRoutes.newPrescription),
        ),
        const HBGap.sm(),
        HBButton(
          label: 'Importar receita ou prescrição',
          onPressed: () => context.push(AppRoutes.importPrescription),
        ),
      ],
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.prescription, required this.onTap});
  final MedicalPrescription prescription;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => HBCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          prescription.professionalName?.trim().isNotEmpty ?? false
              ? prescription.professionalName!
              : 'Prescrição sem profissional informado',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const HBGap.sm(),
        HBText(AppDateFormatter.short(prescription.prescribedAt)),
        HBText('${prescription.activeItems.length} item(ns)'),
        HBText(
          '${prescription.linkedItemsCount} adicionado(s) à rotina · ${_status(prescription.status)}',
        ),
        if (prescription.sourceDocumentId != null)
          const HBText('Documento original vinculado'),
      ],
    ),
  );

  static String _status(MedicalPrescriptionStatus value) => switch (value) {
    MedicalPrescriptionStatus.draft => 'Rascunho',
    MedicalPrescriptionStatus.requiresReview => 'Revisar',
    MedicalPrescriptionStatus.confirmed => 'Confirmada',
    MedicalPrescriptionStatus.archived => 'Arquivada',
    MedicalPrescriptionStatus.canceled => 'Cancelada',
  };
}

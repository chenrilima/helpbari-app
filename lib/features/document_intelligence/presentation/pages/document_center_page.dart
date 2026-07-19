import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../medical_prescriptions/presentation/providers/medical_prescription_providers.dart';
import '../../domain/entities/document_models.dart';
import '../providers/document_center_provider.dart';

class DocumentCenterPage extends ConsumerWidget {
  const DocumentCenterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentCenterProvider);
    return HBPage(
      appBar: const HBAppBar(
        title: 'Central de Documentos',
        subtitle: 'Originais processados e vínculos clínicos',
      ),
      children: [
        documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const HBText('Não foi possível carregar os documentos.'),
          data: (items) => Column(
            children: [
              if (items.isEmpty)
                const HBEmptyState(
                  title: 'Nenhum documento',
                  description: 'Importe um documento em uma feature clínica.',
                ),
              for (final item in items) ...[
                HBCard(
                  onTap: item.linkedPrescriptionId == null
                      ? null
                      : () async {
                          final prescription = await ref
                              .read(medicalPrescriptionUseCasesProvider)
                              .getById(item.linkedPrescriptionId!);
                          if (prescription != null && context.mounted) {
                            context.push(
                              AppRoutes.prescriptionDetailsPath(
                                prescription.id,
                              ),
                              extra: prescription,
                            );
                          }
                        },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HBText(item.document.fileName),
                      HBText(_type(item.processing?.detectedType)),
                      HBText(_status(item.processing?.status)),
                      HBText(
                        item.isOrphan
                            ? 'Sem registro clínico confirmado'
                            : 'Prescrição vinculada',
                      ),
                    ],
                  ),
                ),
                const HBGap.sm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _type(DetectedDocumentType? type) =>
      type == DetectedDocumentType.prescription
      ? 'Prescrição'
      : type?.name ?? 'Não classificado';
  String _status(ProcessingStatus? status) => switch (status) {
    ProcessingStatus.confirmed => 'Confirmado',
    ProcessingStatus.requiresReview => 'Aguardando revisão',
    ProcessingStatus.failed => 'Falha — tente importar novamente',
    null => 'Aguardando processamento',
    _ => status.name,
  };
}

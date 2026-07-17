import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';
import '../providers/medical_report_providers.dart';
import '../widgets/report_action_bar.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_template_card.dart';

class MedicalReportsPage extends ConsumerWidget {
  const MedicalReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicalReportViewModelProvider);
    final viewModel = ref.read(medicalReportViewModelProvider.notifier);

    ref.listen(medicalReportViewModelProvider, (previous, next) {
      final error = next.errorMessage;

      if (error != null && error != previous?.errorMessage) {
        HBSnackBar.error(context, message: error);
      }
    });

    return HBPage(
      appBar: const HBAppBar(title: 'Relatórios médicos'),
      children: [
        HBText(
          'Gere um PDF consolidado para acompanhamento médico.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const HBGap.xl(),
        DocumentImportCard(
          onConfirmed: (DetectedDocumentType type, List<ExtractedField> fields) {
            HBSnackBar.success(
              context,
              message:
                  'Documento revisado. Relatórios médicos continuam sendo gerados a partir dos dados salvos no app.',
            );
          },
        ),
        const HBGap.xl(),
        const ReportTemplateCard(),
        const HBGap.xl(),
        ReportActionBar(
          isGenerating: state.isGenerating,
          isDownloading: state.isDownloading,
          isSharing: state.isSharing,
          isPrinting: state.isPrinting,
          onGenerate: state.isBusy
              ? null
              : () async {
                  final report = await viewModel.generate();

                  if (context.mounted && report != null) {
                    HBSnackBar.success(
                      context,
                      message: 'Relatório gerado com sucesso.',
                    );
                  }
                },
          onDownload: state.isBusy
              ? null
              : () async {
                  final path = await viewModel.download();

                  if (context.mounted && path != null) {
                    HBSnackBar.success(
                      context,
                      message: 'Relatório salvo com sucesso.',
                    );
                  }
                },
          onShare: state.isBusy
              ? null
              : () async {
                  await viewModel.share();
                },
          onPrint: state.isBusy
              ? null
              : () async {
                  await viewModel.print();
                },
        ),
        if (state.isGenerating) ...[
          const HBGap.xl(),
          const HBLoading(message: 'Gerando relatório médico...'),
        ],
        if (state.errorMessage != null && !state.isBusy) ...[
          const HBGap.xl(),
          HBEmptyState(
            title: 'Não foi possível gerar o relatório',
            description: state.errorMessage!,
            icon: Icons.error_outline,
            actionLabel: 'Tentar novamente',
            onActionPressed: viewModel.retry,
          ),
        ],
        if (state.report != null) ...[
          const HBGap.xl(),
          if (!state.report!.hasClinicalData) ...[
            const HBEmptyState(
              title: 'Relatório sem dados clínicos',
              description:
                  'O PDF foi gerado com campos vazios. Registre informações de saúde para obter um relatório completo.',
              icon: Icons.description_outlined,
            ),
            const HBGap.md(),
          ],
          ReportSummaryCard(report: state.report!),
        ],
      ],
    );
  }
}

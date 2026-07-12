import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../providers/exam_view_model_provider.dart';
import '../states/exam_state.dart';

class ExamDetailsPage extends ConsumerStatefulWidget {
  const ExamDetailsPage({required this.exam, super.key});
  final Exam exam;
  @override
  ConsumerState<ExamDetailsPage> createState() => _ExamDetailsPageState();
}

class _ExamDetailsPageState extends ConsumerState<ExamDetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(examViewModelProvider.notifier).selectExam(widget.exam),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examViewModelProvider);
    final preview = state.attachmentPreview;
    return HBPage(
      appBar: const HBAppBar(title: 'Detalhes do exame'),
      children: [
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HBText(
                widget.exam.formattedName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const HBGap.sm(),
              HBText(widget.exam.formattedDate),
              if (widget.exam.laboratory?.isNotEmpty ?? false) ...[
                const HBGap.sm(),
                HBText(widget.exam.laboratory!),
              ],
              if (widget.exam.notes?.isNotEmpty ?? false) ...[
                const HBGap.sm(),
                HBText(widget.exam.notes!),
              ],
            ],
          ),
        ),
        if (widget.exam.hasAttachment) ...[
          const HBGap.lg(),
          HBText('Anexo', style: Theme.of(context).textTheme.titleMedium),
          const HBGap.sm(),
          if (preview != null && preview.type.name == 'image')
            Image.memory(preview.bytes, height: 220, fit: BoxFit.contain)
          else if (preview != null)
            HBCard(
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined),
                  const HBGap.sm(),
                  Expanded(child: HBText(preview.name)),
                ],
              ),
            )
          else if (state.attachmentStatus == ExamAttachmentStatus.failed)
            HBEmptyState(
              title: 'Anexo indisponível',
              description: state.attachmentError ?? 'Tente novamente.',
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: ref
                  .read(examViewModelProvider.notifier)
                  .loadAttachment,
            )
          else
            const HBLoading(message: 'Carregando anexo...'),
          if (state.attachmentSignedUrl != null) ...[
            const HBGap.sm(),
            const HBText('Link temporário privado gerado para visualização.'),
          ],
        ],
      ],
    );
  }
}

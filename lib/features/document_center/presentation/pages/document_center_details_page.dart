import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/sync/sync.dart';
import '../../../../design_system/design_system.dart';
import '../../../bioimpedance/presentation/providers/bioimpedance_use_cases_provider.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../home/presentation/providers/home_view_model_provider.dart';
import '../../../medical_consultations/presentation/providers/medical_consultation_use_cases_provider.dart';
import '../../../medical_exams/presentation/providers/medical_exam_use_cases_provider.dart';
import '../../../privacy/presentation/providers/privacy_providers.dart';
import '../providers/document_center_providers.dart';

class DocumentCenterDetailsPage extends ConsumerStatefulWidget {
  const DocumentCenterDetailsPage({required this.documentId, super.key});

  final String documentId;

  @override
  ConsumerState<DocumentCenterDetailsPage> createState() =>
      _DocumentCenterDetailsPageState();
}

class _DocumentCenterDetailsPageState
    extends ConsumerState<DocumentCenterDetailsPage> {
  ManagedDocumentRecord? _document;
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = await ref.read(documentCenterServiceProvider.future);
      final document = await service.getDocumentById(widget.documentId);
      if (!mounted) return;
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers
        ..clear()
        ..addEntries(
          (document?.latestFields ?? const <ExtractedField>[]).map(
            (field) => MapEntry(
              field.id,
              TextEditingController(
                text:
                    field.confirmedValue ??
                    field.normalizedValue ??
                    field.rawValue,
              ),
            ),
          ),
        );
      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$error';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOriginal() async {
    await _runAction(() async {
      final service = await ref.read(documentCenterServiceProvider.future);
      final saved = await service.saveOriginal(widget.documentId);
      if (!mounted) return;
      if (saved == null) {
        HBSnackBar.error(
          context,
          message: 'Não foi possível acessar o arquivo original.',
        );
        return;
      }
      HBSnackBar.success(context, message: 'Arquivo disponível em $saved');
    });
  }

  Future<void> _reprocess() async {
    await _runAction(() async {
      final service = await ref.read(documentCenterServiceProvider.future);
      await service.reprocessDocument(widget.documentId);
      if (!mounted) return;
      HBSnackBar.success(context, message: 'Documento reprocessado.');
      await _load();
    });
  }

  Future<void> _retry() async {
    await _runAction(() async {
      final service = await ref.read(documentCenterServiceProvider.future);
      await service.retryProcessing(widget.documentId);
      if (!mounted) return;
      HBSnackBar.success(context, message: 'Processamento reenviado.');
      await _load();
    });
  }

  Future<void> _saveReview() async {
    await _runAction(() async {
      final service = await ref.read(documentCenterServiceProvider.future);
      await service.saveReview(
        documentId: widget.documentId,
        valuesByFieldId: {
          for (final entry in _controllers.entries) entry.key: entry.value.text,
        },
      );
      if (!mounted) return;
      HBSnackBar.success(context, message: 'Revisão confirmada com sucesso.');
      await _load();
      unawaited(ref.read(syncManagerProvider.notifier).syncNow());
    });
  }

  Future<void> _delete() async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir documento?',
      message: 'A exclusão será lógica e sincronizada quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true) return;
    await _runAction(() async {
      final service = await ref.read(documentCenterServiceProvider.future);
      await service.deleteDocument(widget.documentId);
      if (!mounted) return;
      HBSnackBar.success(context, message: 'Documento excluído com sucesso.');
      ref.invalidate(documentCenterViewModelProvider);
      context.pop(true);
    });
  }

  Future<void> _openLink(DocumentClinicalLink link) async {
    switch (link.type) {
      case DocumentClinicalLinkType.medicalExam:
        final exam = await ref
            .read(medicalExamUseCasesProvider)
            .getById(link.entityId);
        if (exam == null || !mounted) return;
        await context.push(AppRoutes.examDetails, extra: exam);
        return;
      case DocumentClinicalLinkType.medicalConsultation:
        final consultation = await ref
            .read(medicalConsultationUseCasesProvider)
            .getById(link.entityId);
        if (consultation == null || !mounted) return;
        await context.push(
          AppRoutes.medicalConsultationDetails,
          extra: consultation,
        );
        return;
      case DocumentClinicalLinkType.bioimpedance:
        final record = await ref
            .read(bioimpedanceUseCasesProvider)
            .getById(link.entityId);
        if (record == null || !mounted) return;
        await context.push(AppRoutes.bioimpedanceDetails, extra: record);
        return;
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
      ref.invalidate(documentCenterServiceProvider);
      ref.invalidate(documentCenterViewModelProvider);
      ref.invalidate(homeViewModelProvider);
      ref.invalidate(privacyExportServiceProvider);
    } catch (error) {
      if (!mounted) return;
      HBSnackBar.error(context, message: '$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    final processing = document?.latestProcessing;
    return HBLoadingOverlay(
      isLoading: _isLoading,
      message: 'Atualizando documento...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Detalhes do documento',
          subtitle: 'Revise campos, vínculos e status do processamento',
        ),
        children: [
          if (_errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar o documento',
              description: _errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _load,
            )
          else if (document == null)
            const HBEmptyState(
              title: 'Documento não encontrado',
              description: 'O documento pode ter sido removido da sua conta.',
              icon: Icons.folder_off_outlined,
            )
          else ...[
            HBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HBText(
                    document.document.fileName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const HBGap.sm(),
                  HBText(
                    'Tipo: ${_typeLabel(processing?.detectedType ?? DetectedDocumentType.unknown)}',
                  ),
                  HBText('Status: ${_statusText(processing?.status)}'),
                  HBText(
                    'Capturado em: ${AppDateFormatter.shortWithTime(document.document.capturedAt)}',
                  ),
                  HBText('Tamanho: ${_fileSize(document.document.fileSize)}'),
                  HBText(
                    document.isOrphan
                        ? 'Vínculo: documento órfão'
                        : 'Vínculo: documento relacionado',
                  ),
                ],
              ),
            ),
            const HBGap.md(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HBButton(
                  label: 'Salvar original',
                  onPressed: document.hasOriginalFile ? _saveOriginal : null,
                ),
                HBButton(
                  label: 'Reprocessar',
                  onPressed:
                      document.document.localPath?.trim().isNotEmpty == true
                      ? _reprocess
                      : null,
                ),
                HBButton(
                  label: 'Retry',
                  onPressed:
                      processing?.status == ProcessingStatus.failed &&
                          document.document.localPath?.trim().isNotEmpty == true
                      ? _retry
                      : null,
                ),
                HBButton(label: 'Excluir', onPressed: _delete),
              ],
            ),
            const HBGap.lg(),
            if (document.links.isNotEmpty) ...[
              HBText(
                'Vínculos clínicos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const HBGap.sm(),
              for (final link in document.links) ...[
                HBCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HBText(link.title),
                            if ((link.subtitle?.trim().isNotEmpty ?? false))
                              HBText(link.subtitle!),
                          ],
                        ),
                      ),
                      HBButton(
                        label: 'Abrir',
                        onPressed: () => _openLink(link),
                      ),
                    ],
                  ),
                ),
                const HBGap.sm(),
              ],
            ],
            if (document.latestFields.isNotEmpty) ...[
              HBText(
                'Campos extraídos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const HBGap.sm(),
              for (final field in document.latestFields) ...[
                HBTextField(
                  controller: _controllers[field.id]!,
                  label: field.label,
                ),
                const HBGap.sm(),
              ],
              HBButton(label: 'Confirmar revisão', onPressed: _saveReview),
            ] else
              const HBEmptyState(
                title: 'Sem campos revisáveis',
                description:
                    'Este documento não trouxe campos estruturados para confirmação.',
                icon: Icons.rule_folder_outlined,
              ),
          ],
        ],
      ),
    );
  }
}

String _statusText(ProcessingStatus? value) => switch (value) {
  ProcessingStatus.pending => 'Pendente',
  ProcessingStatus.processing => 'Processando',
  ProcessingStatus.processed => 'Processado',
  ProcessingStatus.requiresReview => 'Aguardando revisão',
  ProcessingStatus.confirmed => 'Confirmado',
  ProcessingStatus.failed => 'Falhou',
  null => 'Desconhecido',
};

String _typeLabel(DetectedDocumentType value) => switch (value) {
  DetectedDocumentType.labResult => 'Resultado de exame',
  DetectedDocumentType.medicalExamReport => 'Laudo de exame',
  DetectedDocumentType.medicalConsultation => 'Consulta médica',
  DetectedDocumentType.consultationNote => 'Anotação de consulta',
  DetectedDocumentType.medicalReport => 'Relatório',
  DetectedDocumentType.prescription => 'Receita',
  DetectedDocumentType.examRequest => 'Pedido de exames',
  DetectedDocumentType.bioimpedanceReport => 'Bioimpedância',
  DetectedDocumentType.unknown => 'Desconhecido',
};

String _fileSize(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  return '$value B';
}

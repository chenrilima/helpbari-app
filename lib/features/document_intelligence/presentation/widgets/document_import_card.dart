import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/media.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../../design_system/design_system.dart';
import '../../../../shared/widgets/media/media_widgets.dart';
import '../../application/document_processing_service.dart';
import '../../domain/entities/document_models.dart';
import '../../domain/repositories/document_intelligence_contracts.dart';
import '../providers/document_intelligence_providers.dart';

typedef DocumentConfirmed =
    void Function(DetectedDocumentType type, List<ExtractedField> fields);

class DocumentImportCard extends ConsumerStatefulWidget {
  const DocumentImportCard({
    required this.onConfirmed,
    this.onProcessingConfirmed,
    super.key,
  });
  final DocumentConfirmed onConfirmed;
  final ValueChanged<DocumentProcessing>? onProcessingConfirmed;

  @override
  ConsumerState<DocumentImportCard> createState() => _DocumentImportCardState();
}

class _DocumentImportCardState extends ConsumerState<DocumentImportCard> {
  static const _documentProcessingConfig = MediaProcessingConfig(
    compressImages: false,
    cropImages: false,
    cacheFiles: true,
  );

  DocumentProcessing? _processing;
  List<ExtractedField> _fields = const [];
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HBText('Adicionar documento'),
          const HBGap.sm(),
          const HBText(
            'A BarIA ajuda a organizar a leitura. Nenhum dado será salvo sem sua confirmação.',
          ),
          const HBGap.md(),
          MediaAttachmentPicker(
            label: 'Documento para análise',
            emptyLabel: 'Tirar foto ou escolher arquivo',
            initialFiles: const [],
            processingConfig: _documentProcessingConfig,
            onChanged: (files) {
              if (files.isNotEmpty) _process(files.single);
            },
            onError: (error) =>
                HBSnackBar.error(context, message: error.message),
          ),
          if (_loading) ...[
            const HBGap.md(),
            const Center(child: CircularProgressIndicator()),
            const HBGap.sm(),
            const HBText('BarIA está analisando seu documento.'),
          ],
          if (_processing?.status == ProcessingStatus.failed) ...[
            const HBGap.md(),
            HBText(
              _processing!.errorMessage ??
                  'Não foi possível analisar o documento.',
            ),
          ],
          if (_processing != null &&
              _processing!.status != ProcessingStatus.failed) ...[
            const HBGap.lg(),
            HBText('Possível tipo: ${_typeLabel(_processing!.detectedType)}'),
            const HBGap.sm(),
            HBText(
              'Confiança: ${_processing!.generalConfidence.confidenceLevel.name}',
            ),
            const HBGap.md(),
            if (_fields.isEmpty) ...[
              const HBText(
                'Não encontramos campos legíveis para preencher automaticamente. '
                'Tente uma foto mais aproximada, com melhor contraste, ou recorte apenas a área das medidas.',
              ),
              const HBGap.md(),
            ],
            for (final field in _fields) ...[
              HBTextField(
                controller: _controllers[field.id]!,
                label:
                    '${field.label}${field.confidence < 0.8 ? ' — revisar' : ''}',
              ),
              const HBGap.sm(),
            ],
            const HBText(
              'Revise os dados extraídos. O HelpBari pode cometer erros de leitura.',
            ),
            const HBGap.md(),
            HBButton(
              label: 'Confirmar dados revisados',
              onPressed: _fields.isEmpty ? null : _confirm,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _process(MediaFile file) async {
    final userId = ref.read(currentUserIdProvider);
    final path = file.path;
    if (userId == null || path == null) {
      HBSnackBar.error(
        context,
        message: 'O arquivo original não está disponível.',
      );
      return;
    }
    setState(() => _loading = true);
    final uuid = ref.read(uuidServiceProvider);
    final now = ref.read(clockServiceProvider).now().toUtc();
    final document = DocumentInput(
      id: uuid.generate(),
      userId: userId,
      sourceType: switch (file.source) {
        MediaSource.camera => DocumentSourceType.camera,
        MediaSource.gallery => DocumentSourceType.gallery,
        MediaSource.files =>
          file.type == MediaFileType.pdf
              ? DocumentSourceType.pdf
              : DocumentSourceType.file,
        null => DocumentSourceType.file,
      },
      localPath: path,
      mimeType: file.mimeType,
      fileName: file.name,
      fileSize: file.sizeInBytes,
      checksum: sha256.convert(file.bytes).toString(),
      capturedAt: now,
      createdAt: now,
    );
    final processingId = uuid.generate();
    final repository = await ref.read(
      documentProcessingRepositoryProvider.future,
    );
    try {
      await repository.saveDocument(document);
      unawaited(_uploadOriginal(repository, document, file.bytes));
      final result = await ref
          .read(documentProcessingServiceProvider)
          .process(document: document, processingId: processingId, now: now);
      await repository.saveProcessing(userId, result.processing);
      await repository.replaceFields(userId, processingId, result.fields);
      if (!mounted) return;
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers
        ..clear()
        ..addEntries(
          result.fields.map(
            (field) => MapEntry(
              field.id,
              TextEditingController(
                text: field.normalizedValue ?? field.rawValue,
              ),
            ),
          ),
        );
      setState(() {
        _processing = result.processing;
        _fields = result.fields;
      });
    } catch (_) {
      if (!mounted) return;
      HBSnackBar.error(
        context,
        message: 'Não foi possível analisar o documento com segurança.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadOriginal(
    DocumentProcessingRepository repository,
    DocumentInput document,
    List<int> bytes,
  ) async {
    try {
      final remotePath = await ref
          .read(documentStorageGatewayProvider)
          .upload(
            userId: document.userId,
            documentId: document.id,
            fileName: document.fileName,
            mimeType: document.mimeType,
            bytes: Uint8List.fromList(bytes),
          );
      await repository.updateDocumentRemotePath(
        userId: document.userId,
        documentId: document.id,
        remotePath: remotePath,
        updatedAt: ref.read(clockServiceProvider).now().toUtc(),
      );
    } catch (error) {
      ref
          .read(loggerServiceProvider)
          .warning('Document upload deferred (${error.runtimeType}).');
    }
  }

  Future<void> _confirm() async {
    final processing = _processing;
    final userId = ref.read(currentUserIdProvider);
    if (processing == null || userId == null) return;
    final now = ref.read(clockServiceProvider).now().toUtc();
    final review = const DocumentReviewService();
    final edited = _fields
        .map((field) => review.edit(field, _controllers[field.id]!.text, now))
        .toList(growable: false);
    final confirmed = review.confirm(edited, now);
    final confirmedProcessing = DocumentProcessing(
      id: processing.id,
      documentId: processing.documentId,
      status: ProcessingStatus.confirmed,
      detectedType: processing.detectedType,
      rawText: processing.rawText,
      engine: processing.engine,
      engineVersion: processing.engineVersion,
      generalConfidence: processing.generalConfidence,
      startedAt: processing.startedAt,
      completedAt: processing.completedAt,
      createdAt: processing.createdAt,
      updatedAt: now,
    );
    final repository = await ref.read(
      documentProcessingRepositoryProvider.future,
    );
    await repository.saveProcessing(userId, confirmedProcessing);
    await repository.replaceFields(userId, processing.id, confirmed);
    widget.onProcessingConfirmed?.call(confirmedProcessing);
    widget.onConfirmed(processing.detectedType, confirmed);
    if (mounted) {
      HBSnackBar.success(context, message: 'Documento revisado e confirmado.');
    }
  }

  String _typeLabel(DetectedDocumentType type) => switch (type) {
    DetectedDocumentType.labResult => 'resultado de exame',
    DetectedDocumentType.medicalExamReport => 'laudo de exame laboratorial',
    DetectedDocumentType.medicalConsultation => 'registro de consulta',
    DetectedDocumentType.consultationNote => 'anotação de consulta',
    DetectedDocumentType.medicalReport => 'relatório',
    DetectedDocumentType.prescription => 'receita',
    DetectedDocumentType.examRequest => 'pedido de exames',
    DetectedDocumentType.bioimpedanceReport => 'laudo de bioimpedância',
    DetectedDocumentType.unknown => 'documento não reconhecido',
  };
}

import 'package:flutter/foundation.dart';

import '../../../core/services/services.dart';
import '../../document_intelligence/application/document_processing_service.dart';
import '../../document_intelligence/domain/entities/document_models.dart';
import '../../document_intelligence/domain/repositories/document_intelligence_contracts.dart';
import '../data/services/document_file_saver.dart';
import '../data/services/local_document_reader.dart';

class DocumentCenterService {
  const DocumentCenterService({
    required DocumentProcessingRepository repository,
    required DocumentStorageGateway storage,
    required DocumentProcessingService processingService,
    required ClockService clock,
    required UuidService uuid,
    required LoggerService logger,
    required String userId,
  }) : _repository = repository,
       _storage = storage,
       _processingService = processingService,
       _clock = clock,
       _uuid = uuid,
       _logger = logger,
       _userId = userId;

  final DocumentProcessingRepository _repository;
  final DocumentStorageGateway _storage;
  final DocumentProcessingService _processingService;
  final ClockService _clock;
  final UuidService _uuid;
  final LoggerService _logger;
  final String _userId;

  Stream<List<ManagedDocumentRecord>> watchDocuments() =>
      _repository.watchDocuments(_userId);

  Stream<List<ManagedDocumentRecord>> watchOrphans() =>
      _repository.watchOrphanDocuments(_userId);

  Future<List<ManagedDocumentRecord>> getDocuments() =>
      _repository.getDocuments(_userId);

  Future<List<ManagedDocumentRecord>> searchDocuments(String query) =>
      _repository.searchDocuments(_userId, query: query);

  Future<ManagedDocumentRecord?> getDocumentById(String documentId) =>
      _repository.getDocumentById(_userId, documentId);

  Future<void> deleteDocument(String documentId) {
    return _repository.deleteDocument(
      _userId,
      documentId,
      _clock.now().toUtc(),
    );
  }

  Future<ManagedDocumentRecord?> retryProcessing(String documentId) {
    return reprocessDocument(documentId);
  }

  Future<ManagedDocumentRecord?> reprocessDocument(String documentId) async {
    final current = await getDocumentById(documentId);
    if (current == null) return null;
    final localPath = current.document.localPath;
    if (localPath == null || localPath.trim().isEmpty) {
      throw StateError('O arquivo local não está disponível para reprocessar.');
    }
    final processingId = _uuid.generate();
    final now = _clock.now().toUtc();
    final result = await _processingService.process(
      document: current.document,
      processingId: processingId,
      now: now,
    );
    await _repository.saveProcessing(_userId, result.processing);
    await _repository.replaceFields(_userId, processingId, result.fields);
    return getDocumentById(documentId);
  }

  Future<void> saveReview({
    required String documentId,
    required Map<String, String> valuesByFieldId,
  }) async {
    final current = await getDocumentById(documentId);
    final processing = current?.latestProcessing;
    if (current == null || processing == null) {
      throw StateError('Documento não encontrado para revisão.');
    }
    if (current.latestFields.isEmpty) {
      throw StateError('Nenhum campo disponível para revisão.');
    }
    final now = _clock.now().toUtc();
    final review = const DocumentReviewService();
    final edited = current.latestFields
        .map(
          (field) => review.edit(
            field,
            valuesByFieldId[field.id] ?? field.confirmedValue ?? field.rawValue,
            now,
          ),
        )
        .toList(growable: false);
    final confirmed = review.confirm(edited, now);
    await _repository.saveProcessing(
      _userId,
      DocumentProcessing(
        id: processing.id,
        documentId: processing.documentId,
        status: ProcessingStatus.confirmed,
        detectedType: processing.detectedType,
        rawText: processing.rawText,
        engine: processing.engine,
        engineVersion: processing.engineVersion,
        generalConfidence: processing.generalConfidence,
        errorCode: processing.errorCode,
        errorMessage: processing.errorMessage,
        startedAt: processing.startedAt,
        completedAt: processing.completedAt,
        createdAt: processing.createdAt,
        updatedAt: now,
      ),
    );
    await _repository.replaceFields(_userId, processing.id, confirmed);
  }

  Future<String?> saveOriginal(String documentId) async {
    final document = await getDocumentById(documentId);
    if (document == null) return null;

    Uint8List? bytes;
    final localPath = document.document.localPath;
    if (localPath != null && localPath.trim().isNotEmpty) {
      bytes = await readLocalDocument(localPath);
    }
    bytes ??= await _downloadRemote(document.document.remotePath);
    if (bytes == null) return null;

    return saveDocumentFile(bytes: bytes, fileName: document.document.fileName);
  }

  Future<Uint8List?> _downloadRemote(String? remotePath) async {
    if (remotePath == null || remotePath.trim().isEmpty) return null;
    try {
      return await _storage.download(remotePath);
    } catch (error) {
      _logger.warning(
        'Document download fallback failed (${error.runtimeType}).',
      );
      if (kDebugMode) rethrow;
      return null;
    }
  }
}

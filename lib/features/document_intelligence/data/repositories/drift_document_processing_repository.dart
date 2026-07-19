import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/document_intelligence_dao.dart';
import '../../domain/entities/document_models.dart';
import '../../domain/repositories/document_intelligence_contracts.dart';

class DriftDocumentProcessingRepository
    implements DocumentProcessingRepository {
  const DriftDocumentProcessingRepository(this._dao);
  final DocumentIntelligenceDao _dao;

  @override
  Stream<List<ManagedDocumentRecord>> watchDocuments(String userId) {
    return _dao
        .watchDocumentCenter(userId)
        .asyncMap((_) => getDocuments(userId));
  }

  @override
  Future<List<ManagedDocumentRecord>> getDocuments(String userId) async {
    final documents = await _dao.listDocuments(userId);
    final result = <ManagedDocumentRecord>[];
    for (final row in documents) {
      result.add(await _buildManagedDocument(userId, row));
    }
    return result;
  }

  @override
  Future<ManagedDocumentRecord?> getDocumentById(
    String userId,
    String documentId,
  ) async {
    final row = await _dao.getAnyDocument(userId, documentId);
    if (row == null) return null;
    return _buildManagedDocument(userId, row);
  }

  @override
  Future<List<ManagedDocumentRecord>> searchDocuments(
    String userId, {
    required String query,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getDocuments(userId);
    final documents = await getDocuments(userId);
    return documents
        .where((document) {
          final processing = document.latestProcessing;
          final values = <String>[
            document.document.fileName,
            document.document.mimeType,
            processing?.detectedType.name ?? '',
            processing?.status.name ?? '',
            for (final link in document.links) ...[
              link.title,
              link.subtitle ?? '',
              link.type.name,
            ],
          ];
          return values.join(' ').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  @override
  Stream<List<ManagedDocumentRecord>> watchOrphanDocuments(String userId) {
    return watchDocuments(userId).map(
      (documents) => documents
          .where((document) => document.isOrphan)
          .toList(growable: false),
    );
  }

  @override
  Future<void> saveDocument(DocumentInput document) => _dao.upsertDocument(
    DocumentInputRecordsCompanion.insert(
      id: document.id,
      userId: document.userId,
      sourceType: document.sourceType.name,
      localPath: Value(document.localPath),
      remotePath: Value(document.remotePath),
      mimeType: document.mimeType,
      fileName: document.fileName,
      fileSize: document.fileSize,
      checksum: Value(document.checksum),
      capturedAt: document.capturedAt,
      createdAt: document.createdAt,
      updatedAt: document.createdAt,
      syncStatus: 'pendingCreate',
    ),
  );

  @override
  Future<void> updateDocumentRemotePath({
    required String userId,
    required String documentId,
    required String remotePath,
    required DateTime updatedAt,
  }) => _dao.updateDocumentRemotePath(
    userId: userId,
    documentId: documentId,
    remotePath: remotePath,
    updatedAt: updatedAt,
  );

  @override
  Future<void> saveProcessing(String userId, DocumentProcessing value) =>
      _dao.upsertProcessing(
        DocumentProcessingRecordsCompanion.insert(
          id: value.id,
          userId: userId,
          documentId: value.documentId,
          status: value.status.name,
          detectedType: value.detectedType.name,
          rawText: Value(value.rawText),
          engine: value.engine,
          engineVersion: Value(value.engineVersion),
          generalConfidence: value.generalConfidence.normalizedConfidence,
          errorCode: Value(value.errorCode),
          errorMessage: Value(value.errorMessage),
          startedAt: Value(value.startedAt),
          completedAt: Value(value.completedAt),
          createdAt: value.createdAt,
          updatedAt: value.updatedAt,
          syncStatus: 'pendingCreate',
        ),
      );

  @override
  Future<void> replaceFields(
    String userId,
    String processingId,
    List<ExtractedField> fields,
  ) => _dao.replaceFields(
    userId,
    processingId,
    fields
        .map(
          (field) => ExtractedFieldRecordsCompanion.insert(
            id: field.id,
            userId: userId,
            processingId: field.processingId,
            key: field.key,
            label: field.label,
            rawValue: field.rawValue,
            normalizedValue: Value(field.normalizedValue),
            confirmedValue: Value(field.confirmedValue),
            unit: Value(field.unit),
            confidence: field.confidence.normalizedConfidence,
            status: field.status.name,
            source: field.source.name,
            originalBoundingBox: Value(field.originalBoundingBox),
            createdAt: field.createdAt,
            updatedAt: field.updatedAt,
            syncStatus: 'pendingCreate',
          ),
        )
        .toList(),
  );

  @override
  Future<DocumentProcessing?> getProcessing(
    String userId,
    String processingId,
  ) async {
    final row = await _dao.getProcessing(userId, processingId);
    if (row == null) return null;
    return DocumentProcessing(
      id: row.id,
      documentId: row.documentId,
      status: ProcessingStatus.values.byName(row.status),
      detectedType: DetectedDocumentType.values.byName(row.detectedType),
      rawText: row.rawText,
      engine: row.engine,
      engineVersion: row.engineVersion,
      generalConfidence: row.generalConfidence,
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<List<ExtractedField>> getFields(
    String userId,
    String processingId,
  ) async => (await _dao.getFields(userId, processingId))
      .map(
        (row) => ExtractedField(
          id: row.id,
          processingId: row.processingId,
          key: row.key,
          label: row.label,
          rawValue: row.rawValue,
          normalizedValue: row.normalizedValue,
          confirmedValue: row.confirmedValue,
          unit: row.unit,
          confidence: row.confidence,
          status: FieldStatus.values.byName(row.status),
          source: FieldSource.values.byName(row.source),
          originalBoundingBox: row.originalBoundingBox,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      )
      .toList(growable: false);

  @override
  Future<void> deleteDocument(String userId, String documentId, DateTime at) =>
      _dao.tombstoneDocument(userId, documentId, at);

  Future<ManagedDocumentRecord> _buildManagedDocument(
    String userId,
    DocumentInputRecord row,
  ) async {
    final processing = await _dao.getLatestProcessingForDocument(
      userId,
      row.id,
    );
    final fields = processing == null
        ? const <ExtractedField>[]
        : await getFields(userId, processing.id);
    final examLinks = await _dao.getLinkedMedicalExams(userId, row.id);
    final consultationLinks = await _dao.getLinkedMedicalConsultations(
      userId,
      row.id,
    );
    final bioLinks = await _dao.getLinkedBioimpedanceRecords(userId, row.id);

    return ManagedDocumentRecord(
      document: DocumentInput(
        id: row.id,
        userId: row.userId,
        sourceType: DocumentSourceType.values.byName(row.sourceType),
        localPath: row.localPath,
        remotePath: row.remotePath,
        mimeType: row.mimeType,
        fileName: row.fileName,
        fileSize: row.fileSize,
        checksum: row.checksum,
        capturedAt: row.capturedAt,
        createdAt: row.createdAt,
      ),
      latestProcessing: processing == null
          ? null
          : DocumentProcessing(
              id: processing.id,
              documentId: processing.documentId,
              status: ProcessingStatus.values.byName(processing.status),
              detectedType: DetectedDocumentType.values.byName(
                processing.detectedType,
              ),
              rawText: processing.rawText,
              engine: processing.engine,
              engineVersion: processing.engineVersion,
              generalConfidence: processing.generalConfidence,
              errorCode: processing.errorCode,
              errorMessage: processing.errorMessage,
              startedAt: processing.startedAt,
              completedAt: processing.completedAt,
              createdAt: processing.createdAt,
              updatedAt: processing.updatedAt,
            ),
      latestFields: fields,
      extractedFieldCount: fields.length,
      links: [
        ...examLinks.map(
          (link) => DocumentClinicalLink(
            type: DocumentClinicalLinkType.medicalExam,
            entityId: link.id,
            title: link.title,
            subtitle: link.subtitle,
          ),
        ),
        ...consultationLinks.map(
          (link) => DocumentClinicalLink(
            type: DocumentClinicalLinkType.medicalConsultation,
            entityId: link.id,
            title: link.title,
            subtitle: link.subtitle,
          ),
        ),
        ...bioLinks.map(
          (link) => DocumentClinicalLink(
            type: DocumentClinicalLinkType.bioimpedance,
            entityId: link.id,
            title: link.title,
            subtitle: link.subtitle,
          ),
        ),
      ],
    );
  }
}

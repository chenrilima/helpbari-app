import '../../../../core/database/drift/daos/document_intelligence_dao.dart';
import '../../domain/entities/document_center_entry.dart';
import '../../domain/entities/document_models.dart';

class DriftDocumentCenterRepository {
  const DriftDocumentCenterRepository(this._dao);
  final DocumentIntelligenceDao _dao;

  Future<List<DocumentCenterEntry>> getAll({
    required String userId,
    required Map<String, String> prescriptionIdsByDocument,
  }) async {
    final rows = await _dao.getDocuments(userId);
    final result = <DocumentCenterEntry>[];
    for (final row in rows) {
      final processing = await _dao.getLatestProcessingForDocument(
        userId,
        row.id,
      );
      result.add(
        DocumentCenterEntry(
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
          processing: processing == null
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
          linkedPrescriptionId: prescriptionIdsByDocument[row.id],
        ),
      );
    }
    return result;
  }
}

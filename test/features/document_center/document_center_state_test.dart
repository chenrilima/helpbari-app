import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/document_center/presentation/states/document_center_state.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';

void main() {
  test('filters orphan documents by query and status', () {
    final state = DocumentCenterState(
      documents: [
        _document(
          id: 'doc-1',
          fileName: 'bio.pdf',
          capturedAt: DateTime.utc(2026, 7, 17),
          status: ProcessingStatus.requiresReview,
          type: DetectedDocumentType.bioimpedanceReport,
        ),
        _document(
          id: 'doc-2',
          fileName: 'exame.pdf',
          capturedAt: DateTime.utc(2026, 7, 10),
          status: ProcessingStatus.confirmed,
          type: DetectedDocumentType.medicalExamReport,
          links: const [
            DocumentClinicalLink(
              type: DocumentClinicalLinkType.medicalExam,
              entityId: 'exam-1',
              title: 'Check-up anual',
            ),
          ],
        ),
      ],
      query: 'bio',
      statusFilter: DocumentCenterStatusFilter.requiresReview,
      linkageFilter: DocumentCenterLinkageFilter.orphanOnly,
    );

    final result = state.filtered(DateTime.utc(2026, 7, 18));

    expect(result, hasLength(1));
    expect(result.single.document.id, 'doc-1');
    expect(result.single.isOrphan, isTrue);
  });

  test('filters by period keeping only recent documents', () {
    final state = DocumentCenterState(
      documents: [
        _document(
          id: 'recent',
          fileName: 'recent.pdf',
          capturedAt: DateTime.utc(2026, 7, 16),
          status: ProcessingStatus.confirmed,
          type: DetectedDocumentType.medicalConsultation,
        ),
        _document(
          id: 'old',
          fileName: 'old.pdf',
          capturedAt: DateTime.utc(2026, 5, 1),
          status: ProcessingStatus.confirmed,
          type: DetectedDocumentType.medicalConsultation,
        ),
      ],
      periodFilter: DocumentCenterPeriodFilter.last30Days,
    );

    final result = state.filtered(DateTime.utc(2026, 7, 18));

    expect(result.map((item) => item.document.id), ['recent']);
  });
}

ManagedDocumentRecord _document({
  required String id,
  required String fileName,
  required DateTime capturedAt,
  required ProcessingStatus status,
  required DetectedDocumentType type,
  List<DocumentClinicalLink> links = const [],
}) => ManagedDocumentRecord(
  document: DocumentInput(
    id: id,
    userId: 'user-a',
    sourceType: DocumentSourceType.file,
    mimeType: 'application/pdf',
    fileName: fileName,
    fileSize: 1024,
    capturedAt: capturedAt,
    createdAt: capturedAt,
  ),
  latestProcessing: DocumentProcessing(
    id: 'proc-$id',
    documentId: id,
    status: status,
    detectedType: type,
    engine: 'test',
    generalConfidence: 0.9,
    createdAt: capturedAt,
    updatedAt: capturedAt,
  ),
  links: links,
  extractedFieldCount: 1,
);

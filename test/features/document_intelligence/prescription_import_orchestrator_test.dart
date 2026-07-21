import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/document_intelligence/application/prescription_import_orchestrator.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';
import 'package:helpbari/features/medical_prescriptions/domain/repositories/prescription_platform_repository.dart';

void main() {
  test(
    'preview is stable, review-gated and preserves automatic plus human provenance',
    () {
      const orchestrator = PrescriptionImportOrchestrator(
        platform: _Platform(),
      );
      final now = DateTime.utc(2026, 7, 21);
      final processing = DocumentProcessing(
        id: 'processing-a',
        documentId: 'document-a',
        status: ProcessingStatus.processed,
        detectedType: DetectedDocumentType.prescription,
        engine: 'deterministic',
        generalConfidence: .7,
        createdAt: now,
        updatedAt: now,
      );
      final fields = [
        ExtractedField(
          id: 'field-name',
          processingId: processing.id,
          key: 'item_0.name',
          label: 'Nome',
          rawValue: 'Item OCR',
          normalizedValue: 'Item normalizado',
          confirmedValue: 'Item confirmado',
          confidence: .7,
          status: FieldStatus.confirmed,
          source: FieldSource.ocr,
          createdAt: now,
          updatedAt: now,
        ),
        ExtractedField(
          id: 'field-time',
          processingId: processing.id,
          key: 'item_0.schedule_time',
          label: 'Horário',
          rawValue: '8h',
          normalizedValue: '08:00',
          confidence: .75,
          status: FieldStatus.uncertain,
          source: FieldSource.ocr,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final first = orchestrator.preview(
        userId: 'user-a',
        processing: processing,
        fields: fields,
        now: now,
      );
      final retry = orchestrator.preview(
        userId: 'user-a',
        processing: processing,
        fields: fields,
        now: now,
      );

      expect(first.prescription.id, retry.prescription.id);
      expect(
        first.prescription.items.single.id,
        retry.prescription.items.single.id,
      );
      expect(first.requiresReview, isTrue);
      expect(first.prescription.items.single.name, 'Item confirmado');
      expect(first.prescription.items.single.scheduleTimes, ['08:00']);
      expect(
        first.prescription.items.single.provenance['item_0.name'],
        'ocr:field-name|humanConfirmed',
      );
    },
  );
}

class _Platform implements PrescriptionPlatformRepository {
  const _Platform();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

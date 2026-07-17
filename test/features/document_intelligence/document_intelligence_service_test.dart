import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/document_intelligence/application/deterministic_document_classifier.dart';
import 'package:helpbari/features/document_intelligence/application/document_processing_service.dart';
import 'package:helpbari/features/document_intelligence/application/parsers/deterministic_parsers.dart';
import 'package:helpbari/features/document_intelligence/data/datasources/ml_kit_document_text_extractor.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';
import 'package:helpbari/features/document_intelligence/domain/repositories/document_intelligence_contracts.dart';

void main() {
  group('Document Intelligence', () {
    test('classifies and parses a lab result deterministically', () {
      const classifier = DeterministicDocumentClassifier();
      const parser = LabResultParser();
      const text = '''
Laboratório: Bari Lab
Exame: Hemograma completo
Data: 17/07/2026
Glicose: 92 mg/dL
''';

      final candidate = classifier.classify(text);
      final fields = parser.parse(processingId: 'processing-1', text: text);

      expect(candidate.type, DetectedDocumentType.labResult);
      expect(fields.map((field) => field.key), contains('laboratory'));
      expect(fields.map((field) => field.key), contains('exam_name'));
      expect(fields.map((field) => field.key), contains('result'));
    });

    test(
      'review keeps raw value and stores user confirmed value separately',
      () {
        final now = DateTime.utc(2026, 7, 17);
        const review = DocumentReviewService();
        final field = ExtractedField(
          id: 'field-1',
          processingId: 'processing-1',
          key: 'dosage',
          label: 'Dose',
          rawValue: '2O mg',
          normalizedValue: '2O mg',
          confidence: 0.52,
          status: FieldStatus.extracted,
          source: FieldSource.ocr,
          createdAt: now,
          updatedAt: now,
        );

        final edited = review.edit(field, '20 mg', now);
        final confirmed = review.confirm([edited], now).single;

        expect(confirmed.rawValue, '2O mg');
        expect(confirmed.confirmedValue, '20 mg');
        expect(confirmed.status, FieldStatus.confirmed);
        expect(confirmed.source, FieldSource.ocrEdited);
      },
    );

    test(
      'returns a safe failed processing when extractor cannot read input',
      () async {
        final now = DateTime.utc(2026, 7, 17);
        final service = DocumentProcessingService(
          extractor: const _FailingExtractor(),
          classifier: const DeterministicDocumentClassifier(),
          parsers: const [PrescriptionParser()],
        );

        final result = await service.process(
          document: DocumentInput(
            id: 'document-1',
            userId: 'user-1',
            sourceType: DocumentSourceType.pdf,
            localPath: '/tmp/file.pdf',
            mimeType: 'application/pdf',
            fileName: 'file.pdf',
            fileSize: 10,
            capturedAt: now,
            createdAt: now,
          ),
          processingId: 'processing-1',
          now: now,
        );

        expect(result.processing.status, ProcessingStatus.failed);
        expect(result.processing.errorCode, 'pdf_text_layer_unavailable');
        expect(result.processing.rawText, isNull);
        expect(result.fields, isEmpty);
      },
    );
  });
}

class _FailingExtractor implements DocumentTextExtractor {
  const _FailingExtractor();

  @override
  String get engine => 'test';

  @override
  bool supportsMimeType(String mimeType) => false;

  @override
  Future<String> extract({required String path, required String mimeType}) {
    throw const DocumentExtractionException(
      code: 'pdf_text_layer_unavailable',
      message:
          'PDF ainda não tem extração local de texto disponível neste aparelho.',
    );
  }
}

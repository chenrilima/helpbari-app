import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/features/document_intelligence/data/repositories/drift_document_processing_repository.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';

void main() {
  late AppDatabase database;
  late DriftDocumentProcessingRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftDocumentProcessingRepository(
      database.documentIntelligenceDao,
    );
  });

  tearDown(() => database.close());

  test('schema includes document intelligence tables', () async {
    expect(database.schemaVersion, 13);

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'document_%'",
        )
        .get();

    expect(
      tables.map((row) => row.read<String>('name')),
      contains('document_input_records'),
    );
    expect(
      tables.map((row) => row.read<String>('name')),
      contains('document_processing_records'),
    );
  });

  test(
    'persists processing fields and keeps raw and confirmed values separate',
    () async {
      final now = DateTime.utc(2026, 7, 17);
      await repository.saveDocument(
        DocumentInput(
          id: 'document-1',
          userId: 'user-1',
          sourceType: DocumentSourceType.camera,
          localPath: '/tmp/document.jpg',
          mimeType: 'image/jpeg',
          fileName: 'document.jpg',
          fileSize: 12,
          capturedAt: now,
          createdAt: now,
        ),
      );
      await repository.saveProcessing(
        'user-1',
        DocumentProcessing(
          id: 'processing-1',
          documentId: 'document-1',
          status: ProcessingStatus.confirmed,
          detectedType: DetectedDocumentType.prescription,
          rawText: 'Dose: 2O mg',
          engine: 'test',
          generalConfidence: 0.8,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.replaceFields('user-1', 'processing-1', [
        ExtractedField(
          id: 'field-1',
          processingId: 'processing-1',
          key: 'dosage',
          label: 'Dose',
          rawValue: '2O mg',
          confirmedValue: '20 mg',
          confidence: 0.6,
          status: FieldStatus.confirmed,
          source: FieldSource.ocrEdited,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final fields = await repository.getFields('user-1', 'processing-1');

      expect(fields.single.rawValue, '2O mg');
      expect(fields.single.confirmedValue, '20 mg');
      expect(fields.single.status, FieldStatus.confirmed);
      expect(
        await repository.getFields('another-user', 'processing-1'),
        isEmpty,
      );
    },
  );
}

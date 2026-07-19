import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/core/services/services.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/document_intelligence/domain/entities/document_models.dart';
import 'package:helpbari/features/medical_exams/domain/entities/entities.dart';
import 'package:helpbari/features/medical_reports/domain/entities/entities.dart';
import 'package:helpbari/features/medical_reports/domain/models/models.dart';
import 'package:helpbari/features/privacy/application/privacy_export_service.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';

void main() {
  test(
    'creates an isolated ZIP without tokens, secrets or internal logs',
    () async {
      final service = PrivacyExportService(
        loadReport: () async => _snapshot(),
        loadSettings: () async => const AppSettings(id: 'user-a'),
        loadVitaminLogs: (_, _) async => [],
        loadMedicationLogs: (_, _) async => [],
        loadDocuments: () async => [_document()],
        clock: const _Clock(),
        userId: 'user-a',
      );

      final result = await service.generate();
      final archive = ZipDecoder().decodeBytes(result.bytes);
      final jsonFile = archive.findFile('helpbari-data.json')!;
      final content = utf8.decode(jsonFile.readBytes()!);
      final data = jsonDecode(content) as Map<String, dynamic>;

      expect(result.fileName, endsWith('.zip'));
      expect(data['metadata']['userId'], 'user-a');
      expect(data['water'], isEmpty);
      expect((data['medicalExams'] as List), hasLength(1));
      expect(
        data['medicalExams'][0]['legacyAttachmentPath'],
        '/tmp/exam-legacy.jpg',
      );
      expect(
        data['medicalExams'][0]['results'][0]['canonicalCode'],
        'vitaminD',
      );
      expect((data['documents'] as List), hasLength(1));
      expect(data['documents'][0]['document']['fileName'], 'laudo.pdf');
      expect(data['documents'][0]['links'][0]['type'], 'medicalExam');
      expect(content, isNot(contains('access_token')));
      expect(content, isNot(contains('refresh_token')));
      expect(content, isNot(contains('internal_logs')));
    },
  );

  test('anonymous export is rejected', () async {
    final service = PrivacyExportService(
      loadReport: () async => _snapshot(),
      loadSettings: () async => const AppSettings(id: 'anonymous'),
      loadVitaminLogs: (_, _) async => [],
      loadMedicationLogs: (_, _) async => [],
      loadDocuments: () async => const [],
      clock: const _Clock(),
      userId: 'anonymous',
    );
    await expectLater(service.generate(), throwsStateError);
  });
}

MedicalReportSnapshot _snapshot() => MedicalReportSnapshot(
  generatedAt: DateTime.utc(2026, 7, 16),
  template: ReportTemplate.complete(),
  weightHistory: const [],
  waterHistory: const [],
  vitamins: const [],
  vitaminLogs: const [],
  medications: const [],
  medicationLogs: const [],
  meals: const [],
  appointments: const [],
  consultations: const [],
  exams: [
    MedicalExam(
      id: 'exam-1',
      userId: 'user-a',
      performedAt: DateTime.utc(2026, 7, 15),
      title: 'Check-up anual',
      laboratoryName: 'Lab A',
      legacyAttachmentPath: '/tmp/exam-legacy.jpg',
      source: MedicalExamSource.imported,
      results: [
        MedicalExamResult(
          id: 'result-1',
          medicalExamId: 'exam-1',
          canonicalCode: 'vitaminD',
          canonicalName: 'Vitamina D',
          displayName: 'Vitamina D',
          normalizedName: 'vitamina d',
          valueType: MedicalExamValueType.numeric,
          numericValue: 32,
          unit: 'ng/mL',
          normalizedUnit: 'ng/mL',
          referenceRangeText: '30 - 100',
          source: MedicalExamResultSource.normalizedCatalog,
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
          syncStatus: SyncStatus.synced,
        ),
      ],
      createdAt: DateTime.utc(2026, 7, 15),
      updatedAt: DateTime.utc(2026, 7, 15),
      syncStatus: SyncStatus.synced,
    ),
  ],
  dailySummary: DailySummaryCalculator.calculate(
    waterConsumedMl: 0,
    waterGoalMl: 2000,
    pendingVitamins: 0,
    pendingMedications: 0,
    registeredMeals: 0,
    totalProteinGrams: 0,
    proteinGoalGrams: 0,
  ),
  reportVersion: '1.0',
  periodStart: DateTime.utc(2026, 6, 16),
  averageDailyWaterMl: 0,
  mealsInPeriod: 0,
  averageDailyProteinGrams: 0,
  vitaminAdherencePercent: null,
  medicationAdherencePercent: null,
  automaticObservations: const [],
);

ManagedDocumentRecord _document() => ManagedDocumentRecord(
  document: DocumentInput(
    id: 'doc-1',
    userId: 'user-a',
    sourceType: DocumentSourceType.file,
    localPath: '/tmp/laudo.pdf',
    remotePath: 'documents/user-a/laudo.pdf',
    mimeType: 'application/pdf',
    fileName: 'laudo.pdf',
    fileSize: 4096,
    checksum: 'abc123',
    capturedAt: DateTime.utc(2026, 7, 15, 10),
    createdAt: DateTime.utc(2026, 7, 15, 10),
  ),
  latestProcessing: DocumentProcessing(
    id: 'proc-1',
    documentId: 'doc-1',
    status: ProcessingStatus.confirmed,
    detectedType: DetectedDocumentType.medicalExamReport,
    engine: 'test',
    generalConfidence: 0.92,
    createdAt: DateTime.utc(2026, 7, 15, 10),
    updatedAt: DateTime.utc(2026, 7, 15, 10, 5),
  ),
  latestFields: [
    ExtractedField(
      id: 'field-1',
      processingId: 'proc-1',
      key: 'exam_name',
      label: 'Exame',
      rawValue: 'Vitamina D',
      confidence: 0.88,
      status: FieldStatus.confirmed,
      source: FieldSource.ocr,
      createdAt: DateTime.utc(2026, 7, 15, 10),
      updatedAt: DateTime.utc(2026, 7, 15, 10, 5),
    ),
  ],
  links: const [
    DocumentClinicalLink(
      type: DocumentClinicalLinkType.medicalExam,
      entityId: 'exam-1',
      title: 'Check-up anual',
      subtitle: '15/07/2026',
    ),
  ],
  extractedFieldCount: 1,
);

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 16, 12);
}

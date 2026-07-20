import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/core/services/services.dart';
import 'package:helpbari/core/sync/sync.dart';
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
        loadClinicalData: () async => {
          'documents': [
            {
              'id': 'document-1',
              'remote_path': 'user-a/document-1/original.pdf',
            },
          ],
          'documentProcessings': [
            {'id': 'processing-1', 'status': 'confirmed'},
          ],
          'extractedDocumentFields': [
            {'id': 'field-1', 'confirmed_value': 'confirmed'},
          ],
          'bioimpedance': [
            {'id': 'bio-1', 'body_fat_percentage': 30.0},
          ],
        },
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
      expect(data['documentIntelligence']['documents'], hasLength(1));
      expect(data['documentIntelligence']['processings'], hasLength(1));
      expect(data['documentIntelligence']['extractedFields'], hasLength(1));
      expect(data['documentIntelligence']['originalFilesIncluded'], isFalse);
      expect(data['bioimpedance'], hasLength(1));
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

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 16, 12);
}

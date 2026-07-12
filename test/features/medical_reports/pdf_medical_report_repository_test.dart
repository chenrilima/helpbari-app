import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/features/medical_reports/data/repositories/pdf_medical_report_repository.dart';
import 'package:helpbari/features/medical_reports/domain/entities/entities.dart';
import 'package:helpbari/features/medical_reports/domain/models/medical_report_snapshot.dart';

void main() {
  test('generates a versioned PDF safely with no clinical data', () async {
    final generatedAt = DateTime(2026, 7, 15, 14, 30);
    final snapshot = MedicalReportSnapshot(
      generatedAt: generatedAt,
      template: ReportTemplate.complete(),
      weightHistory: const [],
      waterHistory: const [],
      vitamins: const [],
      vitaminLogs: const [],
      medications: const [],
      medicationLogs: const [],
      meals: const [],
      appointments: const [],
      exams: const [],
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
      periodStart: DateTime(2026, 6, 16),
      averageDailyWaterMl: 0,
      mealsInPeriod: 0,
      averageDailyProteinGrams: 0,
      vitaminAdherencePercent: null,
      medicationAdherencePercent: null,
      automaticObservations: const [
        'Não há dados suficientes para observações clínicas.',
      ],
    );

    final report = await const PdfMedicalReportRepository().generate(
      snapshot: snapshot,
      template: snapshot.template,
    );

    expect(report.bytes, isNotEmpty);
    expect(report.hasClinicalData, isFalse);
    expect(report.reportVersion, '1.0');
    expect(report.fileName, endsWith('.pdf'));
  });
}

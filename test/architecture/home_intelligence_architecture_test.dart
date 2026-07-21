import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home bootstrap does not call broad history APIs', () {
    final source = File(
      'lib/features/home/domain/usecases/health_dashboard_use_cases.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('.getHistory()')));
    expect(source, isNot(contains('.getAll()')));
    expect(source, contains('.getByPeriod('));
  });

  test('section providers never derive from todayDashboardProvider', () {
    final source = File(
      'lib/features/home/presentation/providers/home_view_model_provider.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('watch(todayDashboardProvider)')));
    expect(source, contains('watch(homeHealthSourceProvider.future)'));
    expect(source, contains('watch(homeTreatmentSourceProvider.future)'));
  });

  test('treatment changes do not re-read the health base source', () {
    final source = File(
      'lib/features/home/presentation/providers/home_view_model_provider.dart',
    ).readAsStringSync();
    final baseStart = source.indexOf('final homeHealthBaseSourceProvider');
    final derivedStart = source.indexOf('final homeHealthSourceProvider');
    final treatmentStart = source.indexOf('final homeTreatmentSourceProvider');
    final baseBody = source.substring(baseStart, derivedStart);
    final derivedBody = source.substring(derivedStart, treatmentStart);

    expect(baseBody, isNot(contains('homeTreatmentSourceProvider')));
    expect(derivedBody, contains('homeHealthBaseSourceProvider.future'));
    expect(derivedBody, contains('homeTreatmentSourceProvider.future'));
  });

  test('Home has a single navigational quick-actions section', () {
    final page = File(
      'lib/features/home/presentation/pages/home_page.dart',
    ).readAsStringSync();
    final model = File(
      'lib/features/home/domain/models/home_intelligence_models.dart',
    ).readAsStringSync();

    expect('QuickActionsSection('.allMatches(page), hasLength(1));
    expect(page, contains('IntelligentQuickActionsSection('));
    expect(page, isNot(contains('QuickActionsSection(onOpen:')));
    expect(model, isNot(contains('quickWater')));
  });

  test('Reports uses bounded clinical histories', () {
    final source = File(
      'lib/features/medical_reports/domain/usecases/medical_report_use_cases.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('_weightUseCases.getHistory()')));
    expect(source, isNot(contains('_waterUseCases.getHistory()')));
    expect(source, isNot(contains('_mealUseCases.getAll()')));
    expect(source, isNot(contains('_appointmentUseCases.getAll()')));
    expect(source, isNot(contains('_examUseCases.getHistory()')));
    expect(source, isNot(contains('_prescriptionUseCases?.getAll()')));
    expect(source, isNot(contains('getPendingCount')));
    expect(source, contains('treatmentToday.pendingFor'));
  });

  test('medical exam interval projection batches result reads', () {
    final source = File(
      'lib/features/medical_exams/data/datasources/'
      'drift_medical_exam_local_datasource.dart',
    ).readAsStringSync();

    expect(source, contains('getActiveResultsByExamIds'));
    final rangeMethod = source.substring(source.indexOf('getByPeriod('));
    expect(
      rangeMethod.substring(0, rangeMethod.indexOf('Future<MedicalExam?>')),
      isNot(contains('getActiveResultsByExam(')),
    );
  });

  test('prescription report projection batches item reads', () {
    final source = File(
      'lib/features/medical_prescriptions/data/datasources/'
      'drift_medical_prescription_local_datasource.dart',
    ).readAsStringSync();

    expect(source, contains('getActiveItemsForPrescriptions'));
    expect(source, contains('getLimited({required int limit})'));
  });

  test('Home preserves its previous snapshot during provider refresh', () {
    final source = File(
      'lib/features/home/presentation/pages/home_page.dart',
    ).readAsStringSync();

    expect(source, contains('skipLoadingOnRefresh: true'));
    expect(source, contains('skipLoadingOnReload: true'));
  });

  test('clinical-day and navigation refreshes are scoped', () {
    final source = File(
      'lib/features/home/presentation/pages/home_page.dart',
    ).readAsStringSync();

    expect(source, contains('ref.invalidate(homeClinicalNowProvider)'));
    expect(source, isNot(contains('pushAndRefresh')));
  });

  test('weight trend and prescription review avoid broad consumers', () {
    final source = File(
      'lib/features/home/application/home_intelligence_query_facade.dart',
    ).readAsStringSync();
    final trendStart = source.indexOf('Future<ProgressTrendReadModel>');
    final todayStart = source.indexOf('Future<TodayDashboardReadModel>');
    final trendBody = source.substring(trendStart, todayStart);

    expect(trendBody, contains('weight.getByPeriod'));
    expect(trendBody, isNot(contains('dashboard.load')));
    expect(source, contains('prescriptions.countRequiringReview'));
    expect(source, isNot(contains('prescriptions.getAll')));
  });

  test('session-sensitive consumers reject old asynchronous results', () {
    final sync = File('lib/core/sync/sync_providers.dart').readAsStringSync();
    final baria = File(
      'lib/features/baria/presentation/state/baria_view_model.dart',
    ).readAsStringSync();
    final reports = File(
      'lib/features/medical_reports/presentation/viewmodels/'
      'medical_report_view_model.dart',
    ).readAsStringSync();

    expect(sync, contains('result.belongsTo(currentUserId)'));
    expect(baria, contains('_insightRequest++'));
    expect(baria, contains("ref.read(authSessionProvider)?.id == userId"));
    expect(reports, contains('ref.watch(authSessionProvider)'));
    expect(reports, contains('_isCurrent(request, expectedUserId)'));
  });
}

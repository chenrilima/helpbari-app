import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/baria/application/baria_service.dart';
import 'package:helpbari/features/baria/data/repositories/contextual_baria_repository.dart';
import 'package:helpbari/features/baria/domain/models/models.dart';
import 'package:helpbari/features/home/domain/models/models.dart';
import 'package:helpbari/features/medical_exams/domain/entities/entities.dart';
import 'package:helpbari/features/medical_reports/domain/entities/entities.dart';
import 'package:helpbari/features/medical_reports/domain/models/models.dart';

void main() {
  test('empty context never invents an answer', () async {
    final repository = ContextualBariaRepository(
      _ContextService(_context(userId: 'user-a')),
    );

    final response = await repository.generateResponse(
      'Como foi minha semana?',
    );

    expect(response, contains('Não há dados suficientes'));
    expect(response, contains('não substitui avaliação clínica'));
  });

  test(
    'partial context answers from the same daily aggregate used by Home',
    () async {
      final aggregate = _aggregate([
        _day(waterMl: 1000, waterGoalMl: 2500, score: 0),
      ]);
      final context = _context(userId: 'user-a', today: aggregate);
      final repository = ContextualBariaRepository(_ContextService(context));

      final response = await repository.generateResponse(
        'Quanto falta para a meta?',
      );

      expect(context.todayData, same(aggregate.today));
      expect(response, contains('1000 ml de uma meta de 2500 ml'));
      expect(response, contains('Faltam 1500 ml'));
    },
  );

  test(
    'week summary preserves score zero and uses the supplied aggregate',
    () async {
      final week = _aggregate([
        _day(waterMl: 1000, meals: 2, score: 0),
        _day(waterMl: 2000, meals: 3, score: 80),
      ]);
      final repository = ContextualBariaRepository(
        _ContextService(_context(userId: 'user-a', week: week)),
      );

      final response = await repository.generateResponse(
        'Como foi minha semana?',
      );

      expect(response, contains('média de água de 1500 ml'));
      expect(response, contains('5 refeições'));
      expect(response, contains('Health Score médio de 40'));
    },
  );

  test(
    'offline failures and synchronized state are reported without estimates',
    () async {
      final data = _aggregate([_day(waterMl: 500)]);
      final failed = ContextualBariaRepository(
        _ContextService(
          _context(userId: 'user-a', today: data, syncState: _sync(errors: 2)),
        ),
      );
      final synced = ContextualBariaRepository(
        _ContextService(
          _context(userId: 'user-a', today: data, syncState: _sync(errors: 0)),
        ),
      );

      expect(
        await failed.generateResponse('registros pendentes'),
        contains('2 operação(ões)'),
      );
      expect(
        await synced.generateResponse('sincronização'),
        contains('não deixou operações com falha'),
      );
    },
  );

  test(
    'repositories for different users never share context or history',
    () async {
      final userA = ContextualBariaRepository(
        _ContextService(
          _context(userId: 'user-a', today: _aggregate([_day(waterMl: 700)])),
        ),
      );
      final userB = ContextualBariaRepository(
        _ContextService(
          _context(userId: 'user-b', today: _aggregate([_day(waterMl: 1200)])),
        ),
      );

      expect(await userA.generateResponse('água'), contains('700 ml'));
      expect(await userB.generateResponse('água'), contains('1200 ml'));
      expect((await userA.getContext()).userId, 'user-a');
      expect((await userB.getContext()).userId, 'user-b');
    },
  );

  test(
    'exam response uses medical exams and structured markers without interpretation',
    () async {
      final exam = MedicalExam(
        id: 'exam-1',
        userId: 'user-a',
        performedAt: DateTime.utc(2026, 7, 12),
        title: 'Check-up anual',
        laboratoryName: 'Lab A',
        source: MedicalExamSource.imported,
        results: [
          MedicalExamResult(
            id: 'result-1',
            medicalExamId: 'exam-1',
            canonicalCode: 'ferritin',
            canonicalName: 'Ferritina',
            displayName: 'Ferritina',
            normalizedName: 'ferritina',
            valueType: MedicalExamValueType.numeric,
            numericValue: 45,
            unit: 'ng/mL',
            normalizedUnit: 'ng/mL',
            source: MedicalExamResultSource.normalizedCatalog,
            sortOrder: 0,
            createdAt: DateTime.utc(2026, 7, 12),
            updatedAt: DateTime.utc(2026, 7, 12),
            syncStatus: SyncStatus.synced,
          ),
        ],
        createdAt: DateTime.utc(2026, 7, 12),
        updatedAt: DateTime.utc(2026, 7, 12),
        syncStatus: SyncStatus.synced,
      );
      final repository = ContextualBariaRepository(
        _ContextService(
          _context(
            userId: 'user-a',
            today: _aggregate([_day(waterMl: 1000)], latestExam: exam),
            report: _report(exams: [exam]),
          ),
        ),
      );

      final response = await repository.generateResponse('exames');

      expect(response, contains('Check-up anual'));
      expect(response, contains('1 exame(s) registrado(s)'));
      expect(response, contains('1 resultado(s) estruturado(s)'));
      expect(response, contains('Ferritina'));
      expect(response, contains('não substitui avaliação clínica'));
    },
  );

  test('deterministic insights use only context values', () {
    final today = _aggregate([
      _day(waterMl: 2000, meals: null, pendingVitamins: 1),
    ]);
    final week = _aggregate([_day(waterMl: 1000), _day(waterMl: 2000)]);
    final service = _ContextService(
      _context(userId: 'user-a', today: today, week: week),
    );

    final first = service.insights(service.context);
    final second = service.insights(service.context);

    expect(first, orderedEquals(second));
    expect(first, contains('Ainda não há refeição registrada hoje.'));
    expect(
      first,
      contains('Há registros de vitaminas ou medicamentos pendentes hoje.'),
    );
  });
}

class _ContextService implements BariaContextService {
  _ContextService(this.context);

  final BariaContext context;

  @override
  Future<BariaContext> buildContext() async => context;

  @override
  List<String> insights(BariaContext context) {
    final result = <String>[];
    if (context.todayData?.mealsCount == null) {
      result.add('Ainda não há refeição registrada hoje.');
    }
    if ((context.todayData?.pendingVitamins ?? 0) > 0 ||
        (context.todayData?.pendingMedications ?? 0) > 0) {
      result.add('Há registros de vitaminas ou medicamentos pendentes hoje.');
    }
    return result;
  }
}

BariaContext _context({
  required String userId,
  HealthDashboardAggregate? today,
  HealthDashboardAggregate? week,
  HealthDashboardAggregate? month,
  MedicalReportSnapshot? report,
  SyncState syncState = const SyncState(),
}) => BariaContext(
  userId: userId,
  generatedAt: DateTime(2026, 7, 12, 12),
  today: today,
  week: week,
  month: month,
  report: report,
  syncState: syncState,
);

HealthDashboardAggregate _aggregate(
  List<DailyHealthAggregate> days, {
  MedicalExam? latestExam,
}) => HealthDashboardAggregate(
  periodStart: days.first.date,
  periodEnd: days.last.date,
  days: days,
  unavailableSections: const {},
  latestExam: latestExam,
);

DailyHealthAggregate _day({
  int? waterMl,
  int? waterGoalMl = 2500,
  int? meals,
  int? score,
  int? pendingVitamins,
  int? pendingMedications,
}) => DailyHealthAggregate(
  date: DateTime(2026, 7, 12),
  waterMl: waterMl,
  waterGoalMl: waterGoalMl,
  mealsCount: meals,
  proteinGrams: null,
  vitaminAdherence: null,
  medicationAdherence: null,
  weightKg: null,
  healthScore: HealthScoreResult(
    score: score ?? 0,
    hydrationScore: 0,
    proteinScore: 0,
    vitaminsScore: 0,
    medicationsScore: 0,
    mealsScore: 0,
    weightProgressScore: 0,
    availableWeight: score == null ? 0 : 1,
  ),
  pendingVitamins: pendingVitamins,
  pendingMedications: pendingMedications,
);

SyncState _sync({required int errors}) {
  final date = DateTime(2026, 7, 12, 11);
  return SyncState(
    phase: errors == 0 ? SyncPhase.success : SyncPhase.failure,
    lastSyncAt: date,
    lastResult: SyncResult(
      startedAt: date,
      completedAt: date,
      repositoriesProcessed: 1,
      pushed: 0,
      pulled: 0,
      deleted: 0,
      conflicts: const [],
      errors: List.generate(
        errors,
        (_) => const SyncError(repositoryKey: 'water', message: 'offline'),
      ),
    ),
  );
}

MedicalReportSnapshot _report({required List<MedicalExam> exams}) =>
    MedicalReportSnapshot(
      generatedAt: DateTime.utc(2026, 7, 12),
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
      exams: exams,
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
      periodStart: DateTime.utc(2026, 6, 12),
      averageDailyWaterMl: 0,
      mealsInPeriod: 0,
      averageDailyProteinGrams: 0,
      vitaminAdherencePercent: null,
      medicationAdherencePercent: null,
      automaticObservations: const [],
    );

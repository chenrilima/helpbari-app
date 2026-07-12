import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/health/health.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/baria/application/baria_service.dart';
import 'package:helpbari/features/baria/data/repositories/contextual_baria_repository.dart';
import 'package:helpbari/features/baria/domain/models/models.dart';
import 'package:helpbari/features/home/domain/models/models.dart';

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
  SyncState syncState = const SyncState(),
}) => BariaContext(
  userId: userId,
  generatedAt: DateTime(2026, 7, 12, 12),
  today: today,
  week: week,
  month: month,
  report: null,
  syncState: syncState,
);

HealthDashboardAggregate _aggregate(List<DailyHealthAggregate> days) =>
    HealthDashboardAggregate(
      periodStart: days.first.date,
      periodEnd: days.last.date,
      days: days,
      unavailableSections: const {},
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

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/home/domain/models/home_intelligence_models.dart';
import 'package:helpbari/features/home/domain/services/deterministic_insight_engine.dart';
import 'package:helpbari/features/smart_routines/domain/services/treatment_query_models.dart';

void main() {
  const engine = DeterministicInsightEngine();
  final now = DateTime(2026, 7, 21, 18);

  test('time-aware rules deduplicate and declare cooldown and expiration', () {
    final feed = engine.generate(
      _input(now: now, waterMl: 200, waterGoalMl: 2000),
    );

    final hydration = feed.insights.singleWhere(
      (value) => value.ruleId == 'hydration-pace',
    );
    expect(hydration.deduplicationKey, 'hydration-pace:2026-07-21');
    expect(hydration.cooldown, const Duration(hours: 4));
    expect(hydration.expiresAt, DateTime(2026, 7, 22));
    expect(
      feed.insights.map((value) => value.deduplicationKey).toSet().length,
      feed.insights.length,
    );
  });

  test('insufficient coverage is information and never zero adherence', () {
    final feed = engine.generate(_input(now: now));
    final insight = feed.insights.singleWhere(
      (value) => value.ruleId == 'treatment-coverage',
    );

    expect(insight.coverage.state, CoverageState.insufficient);
    expect(insight.message, contains('dados suficientes'));
  });

  test('messages preserve safe non-prescriptive language', () {
    final feed = engine.generate(
      _input(
        now: now,
        waterMl: 100,
        waterGoalMl: 2000,
        prescriptionsAwaitingReview: 1,
        pendingSync: true,
      ),
    );
    final text = feed.insights
        .expand((value) => [value.title, value.message])
        .join(' ')
        .toLowerCase();

    for (final forbidden in [
      'tome agora',
      'compense',
      'ajuste a dose',
      'interrompa',
      'é seguro',
      'diagnóstico',
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
  });
}

DeterministicInsightInput _input({
  required DateTime now,
  int? waterMl,
  int? waterGoalMl,
  int prescriptionsAwaitingReview = 0,
  bool pendingSync = false,
}) {
  final freshness = FreshnessReadModel(generatedAt: now);
  const coverage = CoverageReadModel(
    state: CoverageState.insufficient,
    reason: 'Sem denominador avaliável',
    formulaVersion: 'treatment-adherence-v1',
  );
  final status = HomeSectionStatus(
    state: HomeSectionState.ready,
    freshness: freshness,
    coverage: coverage,
  );
  final treatment = TreatmentSummaryReadModel(
    due: 0,
    open: 0,
    resolved: 0,
    missed: 0,
    requiresReview: 0,
    adherence: null,
    onTimeAdherence: null,
    coverage: coverage,
    origin: TreatmentDataOrigin.smartRoutines,
    formulaVersion: 'treatment-adherence-v1',
    adherenceByCategory: const {},
    status: status,
  );
  return DeterministicInsightInput(
    now: now,
    timeZone: 'America/Sao_Paulo',
    waterMl: waterMl,
    waterGoalMl: waterGoalMl,
    proteinGrams: null,
    proteinGoalGrams: null,
    treatment: treatment,
    agenda: AgendaReadModel(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day + 7),
      items: const [],
      status: status,
    ),
    prescriptionsAwaitingReview: prescriptionsAwaitingReview,
    pendingSync: pendingSync,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/baria/domain/models/models.dart';
import 'package:helpbari/features/baria/domain/services/baria_insight_engine.dart';
import 'package:helpbari/features/home/domain/models/home_intelligence_models.dart';
import 'package:helpbari/features/smart_routines/domain/services/treatment_query_models.dart';

void main() {
  const engine = BariaInsightEngine();

  test('adapts canonical insights without recalculating rules', () {
    final context = _context('user-a');
    final insights = engine.generate(context);

    expect(insights, hasLength(1));
    expect(insights.single.id, 'water:2026-07-21:v1');
    expect(insights.single.priority, BariaInsightPriority.high);
    expect(insights.single.category, BariaInsightCategory.water);
    expect(insights.single.action.destination, '/water');
  });

  test('rejects a snapshot from another user', () {
    final original = _context('user-a');
    final mismatched = BariaContext(
      userId: 'user-b',
      generatedAt: original.generatedAt,
      today: null,
      week: null,
      month: null,
      report: null,
      syncState: const SyncState(),
      intelligence: original.intelligence,
    );

    expect(engine.generate(mismatched), isEmpty);
  });
}

BariaContext _context(String userId) {
  final now = DateTime(2026, 7, 21, 18);
  final freshness = FreshnessReadModel(generatedAt: now);
  final status = HomeSectionStatus(
    state: HomeSectionState.ready,
    freshness: freshness,
  );
  const coverage = CoverageReadModel(state: CoverageState.sufficient, rate: 1);
  final insight = DeterministicInsightReadModel(
    id: 'water:2026-07-21:v1',
    ruleId: 'hydration-pace',
    ruleVersion: '1',
    title: 'Hidratação em progresso',
    message: 'Os registros estão abaixo da progressão da meta.',
    priority: InsightPriority.high,
    sources: const ['water'],
    deduplicationKey: 'water:2026-07-21',
    expiresAt: DateTime(2026, 7, 22),
    cooldown: const Duration(hours: 4),
    coverage: coverage,
    disclaimer: 'Informação de acompanhamento.',
    deepLink: '/water',
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
    formulaVersion: 'v1',
    adherenceByCategory: const {},
    status: status,
  );
  final unavailableMetric = ProgressMetricReadModel(
    id: 'unavailable',
    label: 'Indisponível',
    state: ProgressMetricState.unavailable,
    coverage: const CoverageReadModel(state: CoverageState.unavailable),
  );
  final dashboard = TodayDashboardReadModel(
    userId: userId,
    clinicalDate: DateTime(2026, 7, 21),
    timeZone: 'America/Sao_Paulo',
    nextActions: NextActionsReadModel(actions: const [], status: status),
    agenda: AgendaReadModel(
      start: DateTime(2026, 7, 21),
      end: DateTime(2026, 7, 28),
      items: const [],
      status: status,
    ),
    treatment: treatment,
    progress: ProgressSummaryReadModel(
      routine: unavailableMetric,
      water: unavailableMetric,
      protein: unavailableMetric,
      weight: unavailableMetric,
      healthScore: unavailableMetric,
      streak: unavailableMetric,
      status: status,
    ),
    quickStats: QuickStatsReadModel(
      waterLabel: '—',
      proteinLabel: '—',
      routineLabel: '—',
      status: status,
    ),
    quickActions: QuickActionsReadModel(
      fixed: const [],
      dynamic: const [],
      status: status,
    ),
    insights: InsightFeedReadModel(insights: [insight], status: status),
    status: status,
  );
  return BariaContext(
    userId: userId,
    generatedAt: now,
    today: null,
    week: null,
    month: null,
    report: null,
    syncState: const SyncState(),
    intelligence: dashboard,
  );
}

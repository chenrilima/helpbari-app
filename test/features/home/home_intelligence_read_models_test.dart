import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/home/domain/models/home_intelligence_models.dart';

void main() {
  final now = DateTime(2026, 7, 21, 8);
  final status = HomeSectionStatus(
    state: HomeSectionState.ready,
    freshness: FreshnessReadModel(generatedAt: now),
  );

  test('agenda groups canonical items by clinical date', () {
    final agenda = AgendaReadModel(
      start: now,
      end: now.add(const Duration(days: 7)),
      items: [_item('a', now), _item('b', now.add(const Duration(days: 1)))],
      status: status,
    );

    expect(agenda.groupedByDate, hasLength(2));
    expect(agenda.groupedByDate[DateTime(2026, 7, 21)]?.single.id, 'a');
  });

  test('next actions enforce the V1 maximum of one', () {
    final model = NextActionsReadModel(
      actions: List.generate(
        5,
        (index) => NextActionReadModel(
          id: '$index',
          title: 'Ação $index',
          reason: 'Razão',
          priority: HomeActionPriority.medium,
          source: 'test',
          deepLink: '/home',
          validUntil: now.add(const Duration(days: 1)),
          accessibilityLabel: 'Ação $index',
        ),
      ),
      status: status,
    );

    expect(model.actions, hasLength(1));
  });

  test('coverage unavailable has no fabricated rate', () {
    const coverage = CoverageReadModel(
      state: CoverageState.unavailable,
      reason: 'Dados insuficientes',
    );
    expect(coverage.rate, isNull);
    expect(coverage.hasSufficientData, isFalse);
  });

  test('semantic equality includes immutable collection contents', () {
    final first = AgendaReadModel(
      start: now,
      end: now.add(const Duration(days: 1)),
      items: [_item('a', now)],
      status: status,
    );
    final second = AgendaReadModel(
      start: now,
      end: now.add(const Duration(days: 1)),
      items: [_item('a', now)],
      status: HomeSectionStatus(
        state: HomeSectionState.ready,
        freshness: FreshnessReadModel(generatedAt: now),
      ),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('rejects contradictory coverage and stale freshness', () {
    expect(
      () => CoverageReadModel(state: CoverageState.sufficient),
      throwsAssertionError,
    );
    expect(
      () => FreshnessReadModel(generatedAt: now, isStale: true),
      throwsAssertionError,
    );
    expect(
      () => CoverageReadModel(state: CoverageState.unavailable, rate: .5),
      throwsAssertionError,
    );
  });

  test('rejects invalid actions, intervals, progress and expired insights', () {
    expect(
      () => QuickActionReadModel(
        id: 'water',
        title: 'Água',
        kind: HomeActionKind.route,
        sourceId: 'water',
        accessibilityLabel: 'Abrir água',
      ),
      throwsAssertionError,
    );
    expect(
      () => AgendaReadModel(
        start: now,
        end: now,
        items: const [],
        status: status,
      ),
      throwsAssertionError,
    );
    expect(
      () => ProgressMetricReadModel(
        id: 'water',
        label: 'Água',
        state: ProgressMetricState.available,
        value: 100,
        progress: .5,
        coverage: const CoverageReadModel(
          state: CoverageState.sufficient,
          rate: 1,
        ),
      ),
      throwsAssertionError,
    );
    expect(
      () => InsightFeedReadModel(
        insights: [
          DeterministicInsightReadModel(
            id: 'expired',
            ruleId: 'rule',
            ruleVersion: 'v1',
            title: 'Insight',
            message: 'Mensagem',
            priority: InsightPriority.low,
            sources: const ['water'],
            deduplicationKey: 'expired',
            expiresAt: now,
            cooldown: const Duration(hours: 1),
            coverage: const CoverageReadModel(
              state: CoverageState.sufficient,
              rate: 1,
            ),
            disclaimer: 'Acompanhamento',
          ),
        ],
        status: status,
      ),
      throwsAssertionError,
    );
  });
}

AgendaItemReadModel _item(String id, DateTime at) => AgendaItemReadModel(
  id: id,
  sourceId: id,
  type: AgendaItemType.appointment,
  title: 'Consulta',
  effectiveAt: at,
  timeZone: 'America/Sao_Paulo',
  state: AgendaItemState.future,
  source: 'appointments',
  accessibilityLabel: 'Consulta',
);

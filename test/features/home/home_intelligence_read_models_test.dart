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

  test('next actions enforce the maximum of three', () {
    final model = NextActionsReadModel(
      actions: List.generate(
        5,
        (index) => NextActionReadModel(
          id: '$index',
          title: 'Ação $index',
          reason: 'Razão',
          priority: HomeActionPriority.medium,
          source: 'test',
          validUntil: now.add(const Duration(days: 1)),
          accessibilityLabel: 'Ação $index',
        ),
      ),
      status: status,
    );

    expect(model.actions, hasLength(3));
  });

  test('coverage unavailable has no fabricated rate', () {
    const coverage = CoverageReadModel(
      state: CoverageState.unavailable,
      reason: 'Dados insuficientes',
    );
    expect(coverage.rate, isNull);
    expect(coverage.hasSufficientData, isFalse);
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

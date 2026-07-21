import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/home/domain/models/home_intelligence_models.dart';
import 'package:helpbari/features/home/presentation/widgets/home_intelligence_sections.dart';

void main() {
  testWidgets('upcoming agenda excludes today and identifies future dates', (
    tester,
  ) async {
    final start = DateTime(2026, 7, 21);
    final model = AgendaReadModel(
      start: start,
      end: start.add(const Duration(days: 7)),
      items: [
        _item('today', DateTime(2026, 7, 21, 10)),
        _item('tomorrow', DateTime(2026, 7, 22, 10)),
        _item('later', DateTime(2026, 7, 23, 10)),
      ],
      status: HomeSectionStatus(
        state: HomeSectionState.ready,
        freshness: FreshnessReadModel(generatedAt: start),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IntelligentAgendaSection(
            model: model,
            todayOnly: false,
            onItem: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('today'), findsNothing);
    expect(find.text('tomorrow'), findsOneWidget);
    expect(find.text('later'), findsOneWidget);
    expect(find.text('22/07 • 10:00 • futuro'), findsOneWidget);
    expect(find.text('23/07 • 10:00 • futuro'), findsOneWidget);
  });
}

AgendaItemReadModel _item(String id, DateTime effectiveAt) =>
    AgendaItemReadModel(
      id: id,
      sourceId: id,
      type: AgendaItemType.treatment,
      title: id,
      effectiveAt: effectiveAt,
      timeZone: 'America/Sao_Paulo',
      state: AgendaItemState.future,
      source: 'test',
      accessibilityLabel: id,
    );

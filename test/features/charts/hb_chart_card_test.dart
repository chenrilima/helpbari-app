import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/charts/domain/models/models.dart';
import 'package:helpbari/features/charts/presentation/widgets/hb_chart_card.dart';

void main() {
  testWidgets('renders a zero value as chart data', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HBChartCard(
            title: 'Score',
            period: ChartPeriod.sevenDays,
            onPeriodChanged: (_) {},
            series: ChartSeries(
              title: 'Score diário',
              type: ChartType.line,
              unit: '%',
              points: [ChartPoint(date: DateTime(2026, 7, 15), value: 0)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sem dados suficientes'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Score diário.*0.0')), findsOneWidget);
  });

  testWidgets('offers retry on chart errors', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HBChartCard(
            title: 'Score',
            period: ChartPeriod.sevenDays,
            onPeriodChanged: (_) {},
            series: null,
            errorMessage: 'Falha parcial',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, isTrue);
  });

  testWidgets('empty adherence state does not overflow a narrow card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(313, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HBChartCard(
            title: 'Vitaminas',
            period: ChartPeriod.sevenDays,
            onPeriodChanged: (_) {},
            series: const ChartSeries(
              title: 'Aderência de vitaminas',
              type: ChartType.bar,
              unit: '%',
              points: <ChartPoint>[],
              emptyTitle: 'Sem registros de adesão no período',
              emptyDescription:
                  'Registre tomado, ignorado ou pendente para acompanhar.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sem registros de adesão no período'), findsOneWidget);
  });
}

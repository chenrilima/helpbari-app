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
}

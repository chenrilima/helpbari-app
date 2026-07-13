import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/design_system/design_system.dart';

void main() {
  testWidgets('non-scrollable page gives finite height to expanded content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HBPage(
          scrollable: false,
          children: [
            Text('Cabeçalho'),
            Expanded(child: Center(child: Text('Conteúdo'))),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Cabeçalho'), findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
  });

  testWidgets('scrollable page keeps long form content accessible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HBPage(
          children: [SizedBox(height: 1200, child: Text('Formulário'))],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

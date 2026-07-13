import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/design_system/design_system.dart';

void main() {
  testWidgets('custom dialog remains scrollable with a visible keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: const Size(320, 480),
            viewInsets: const EdgeInsets.only(bottom: 280),
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => HBDialog.custom<void>(
                context,
                title: 'Editar valor',
                content: const SizedBox(height: 240, child: Text('Conteúdo')),
                actions: const [TextButton(onPressed: null, child: Text('OK'))],
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Editar valor'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

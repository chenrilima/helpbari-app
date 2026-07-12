import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/design_system/design_system.dart';

void main() {
  testWidgets('provides a Material ancestor for ListTile ink', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HBCard(child: ListTile(title: Text('Registro'))),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Registro'), findsOneWidget);
  });
}

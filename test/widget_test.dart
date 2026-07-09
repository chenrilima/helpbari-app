import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/app.dart';

void main() {
  testWidgets('renders HelpBari app', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HelpBariApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

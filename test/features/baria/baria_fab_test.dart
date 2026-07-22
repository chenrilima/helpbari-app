import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/baria/presentation/widgets/baria_fab.dart';

void main() {
  testWidgets('global FAB is accessible and opens its callback', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BariaFab(onPressed: () => opened = true)),
      ),
    );

    expect(find.bySemanticsLabel('Abrir assistente BarIA'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    expect(opened, isTrue);
  });

  testWidgets('global app layer provides the Overlay required by FAB tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => BariaGlobalOverlay(
          child: Stack(
            children: <Widget>[
              ?child,
              BariaFab(onPressed: () {}),
            ],
          ),
        ),
        home: const SizedBox.shrink(),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated child updates and removal do not throw', (
    tester,
  ) async {
    final label = ValueNotifier<String>('first');
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<String>(
          valueListenable: label,
          builder: (_, value, _) => BariaGlobalOverlay(child: Text(value)),
        ),
      ),
    );

    for (final value in <String>['second', 'third', 'fourth']) {
      label.value = value;
      await tester.pump();
      expect(find.text(value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    label.dispose();
  });
}

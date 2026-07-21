import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/design_system/design_system.dart';
import 'package:helpbari/features/treatment/presentation/pages/register_treatment_page.dart';

void main() {
  testWidgets('unified form exposes advanced treatment semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const RegisterTreatmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adicionar item'), findsOneWidget);
    expect(find.text('Duração não informada'), findsOneWidget);
    expect(find.text('Adicionar horário'), findsOneWidget);
    expect(
      find.textContaining('histórico permanece preservado'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unified form remains scrollable with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const RegisterTreatmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Programação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

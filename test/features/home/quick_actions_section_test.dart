import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/features/home/presentation/widgets/quick_actions_section.dart';

void main() {
  const expectedRoutes = <String, String>{
    'Água': AppRoutes.water,
    'Medicamentos': AppRoutes.medications,
    'Vitaminas': AppRoutes.vitamins,
    'Prescrições': AppRoutes.prescriptions,
    'Academia': AppRoutes.academy,
    'Configurações': AppRoutes.settings,
    'Peso': AppRoutes.weight,
    'Refeições': AppRoutes.meals,
    'Consultas': AppRoutes.appointments,
    'Exames': AppRoutes.exams,
    'Relatórios': AppRoutes.medicalReports,
    'Documentos': AppRoutes.documentCenter,
  };

  for (final entry in expectedRoutes.entries) {
    testWidgets('${entry.key} opens the official route', (tester) async {
      String? openedRoute;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsSection(onOpen: (route) => openedRoute = route),
          ),
        ),
      );

      final target = find.text(entry.key);
      await tester.scrollUntilVisible(
        target,
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(target);

      expect(openedRoute, entry.value);
    });
  }

  testWidgets('water is navigation only and has no hidden increment action', (
    tester,
  ) async {
    String? openedRoute;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickActionsSection(onOpen: (route) => openedRoute = route),
        ),
      ),
    );

    await tester.tap(find.text('Água'));

    expect(openedRoute, AppRoutes.water);
    expect(find.text('+200 ml'), findsNothing);
  });

  testWidgets('single section supports enlarged text without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: QuickActionsSection(onOpen: (_) {}),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ações rápidas'), findsOneWidget);
    expect(find.text('Minhas ferramentas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

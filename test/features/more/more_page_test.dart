import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/features/more/presentation/pages/more_page.dart';

void main() {
  testWidgets('organizes V1 destinations without exposing prescriptions', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(path: '/more', builder: (_, _) => const MorePage()),
        for (final path in <String>{
          '/appointments',
          '/exams',
          '/documents',
          '/medical-reports',
          '/academy',
          '/academy/history',
          '/profile',
          '/settings',
          '/privacy',
          '/baria',
          '/academy/faq',
        })
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    for (final group in <String>[
      'Acompanhamento',
      'Conteúdo',
      'Conta e preferências',
      'Privacidade e dados',
      'Ajuda',
    ]) {
      await tester.scrollUntilVisible(
        find.text(group),
        250,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text(group), findsOneWidget);
    }
    expect(find.text('Prescrições'), findsNothing);
    expect(find.text('BarIA'), findsOneWidget);
  });

  testWidgets('reports entry uses the canonical reports route', (tester) async {
    String? opened;
    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(path: '/more', builder: (_, _) => const MorePage()),
        GoRoute(
          path: '/medical-reports',
          builder: (_, state) {
            opened = state.uri.path;
            return const Text('Relatórios abertos');
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();

    expect(opened, '/medical-reports');
  });
}

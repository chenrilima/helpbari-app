import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/app/router/app_routes.dart';
import 'package:helpbari/features/home/presentation/widgets/quick_actions_section.dart';

void main() {
  testWidgets('Academy card is accessible and opens the existing route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: QuickActionsSection()),
        ),
        GoRoute(
          path: AppRoutes.academy,
          builder: (_, _) => const Scaffold(body: Text('Academia aberta')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Academia. Artigos e orientações'),
      findsOneWidget,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-1400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Academia'));
    await tester.pumpAndSettle();

    expect(find.text('Academia aberta'), findsOneWidget);
  });
}

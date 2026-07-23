import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/app/shell/main_shell.dart';

void main() {
  testWidgets('shows exactly four areas and preserves branch state', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainShell(navigationShell: shell),
          branches: [
            _branch('/home', 'Hoje'),
            _branch('/treatment', 'Tratamento'),
            _branch('/progress', 'Evolução'),
            _branch('/more', 'Mais'),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('incrementar'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    await tester.tap(find.text('Tratamento'));
    await tester.pumpAndSettle();
    expect(find.text('Tratamento conteúdo'), findsOneWidget);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });
}

StatefulShellBranch _branch(String path, String label) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, _) => _StatefulArea(label: label),
    ),
  ],
);

class _StatefulArea extends StatefulWidget {
  const _StatefulArea({required this.label});
  final String label;

  @override
  State<_StatefulArea> createState() => _StatefulAreaState();
}

class _StatefulAreaState extends State<_StatefulArea> {
  int value = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('${widget.label} conteúdo'),
      Text('$value'),
      TextButton(
        onPressed: () => setState(() => value++),
        child: const Text('incrementar'),
      ),
    ],
  );
}

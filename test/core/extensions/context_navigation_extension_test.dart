import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:helpbari/core/extensions/context_navigation_extension.dart';

void main() {
  testWidgets('awaits asynchronous refresh only for accepted result', (
    tester,
  ) async {
    var refreshes = 0;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const Key('open'),
                  onPressed: () => context.pushAndRefresh<bool>(
                    '/result',
                    onRefresh: () async {
                      await Future<void>.delayed(Duration.zero);
                      refreshes++;
                    },
                    shouldRefresh: (result) => result == true,
                  ),
                  child: const Text('open'),
                ),
                Text('$refreshes'),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const Key('cancel'),
                  onPressed: () => context.pop<bool>(),
                  child: const Text('cancel'),
                ),
                TextButton(
                  key: const Key('save'),
                  onPressed: () => context.pop(true),
                  child: const Text('save'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel')));
    await tester.pumpAndSettle();
    expect(refreshes, 0);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save')));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not refresh after caller is unmounted', (tester) async {
    var refreshes = 0;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pushAndRefresh<void>(
                '/waiting',
                onRefresh: () async => refreshes++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/waiting',
          builder: (context, state) => const Scaffold(body: Text('waiting')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(refreshes, 0);
    expect(tester.takeException(), isNull);
  });
}

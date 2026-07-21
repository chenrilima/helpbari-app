import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';

void main() {
  test('triggers once when transport recovers', () async {
    final changes = StreamController<bool>();
    var calls = 0;
    final trigger = SyncConnectivityTrigger(
      debounce: Duration.zero,
      onRecovered: () async => calls++,
    )..listen(changes.stream);
    addTearDown(() async {
      await trigger.dispose();
      await changes.close();
    });

    changes
      ..add(false)
      ..add(true)
      ..add(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
  });

  test('does not trigger while backgrounded', () async {
    final changes = StreamController<bool>();
    var calls = 0;
    final trigger =
        SyncConnectivityTrigger(
            debounce: Duration.zero,
            onRecovered: () async => calls++,
          )
          ..listen(changes.stream)
          ..setForeground(false);
    addTearDown(() async {
      await trigger.dispose();
      await changes.close();
    });

    changes
      ..add(false)
      ..add(true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 0);
  });

  test('dispose cancels a pending recovery debounce', () async {
    final changes = StreamController<bool>();
    var calls = 0;
    final trigger = SyncConnectivityTrigger(
      debounce: const Duration(milliseconds: 20),
      onRecovered: () async => calls++,
    )..listen(changes.stream);

    changes
      ..add(false)
      ..add(true);
    await Future<void>.delayed(Duration.zero);
    await trigger.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await changes.close();

    expect(calls, 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/home/application/home_runtime_guard.dart';

void main() {
  test('prevents a second quick action while the first is in flight', () {
    final guard = HomeRuntimeGuard();

    expect(guard.begin('quick:water'), isTrue);
    expect(guard.begin('quick:water'), isFalse);
    expect(guard.isInFlight('quick:water'), isTrue);

    guard.complete('quick:water');

    expect(guard.begin('quick:water'), isTrue);
  });

  test('keeps independent actions isolated', () {
    final guard = HomeRuntimeGuard();

    expect(guard.begin('quick:water'), isTrue);
    expect(guard.begin('occurrence:a'), isTrue);
    expect(guard.begin('occurrence:a'), isFalse);
  });

  group('clinical day refresh', () {
    const policy = ClinicalDayRefreshPolicy();

    test('refreshes after midnight', () {
      expect(
        policy.shouldRefresh(
          snapshotDate: DateTime(2026, 7, 21),
          now: DateTime(2026, 7, 22, 0, 1),
          snapshotTimeZone: 'America/Sao_Paulo',
          currentTimeZone: 'America/Sao_Paulo',
        ),
        isTrue,
      );
    });

    test('refreshes after timezone change without changing UTC day', () {
      expect(
        policy.shouldRefresh(
          snapshotDate: DateTime(2026, 7, 21),
          now: DateTime(2026, 7, 21, 20),
          snapshotTimeZone: 'America/Sao_Paulo',
          currentTimeZone: 'Europe/Lisbon',
        ),
        isTrue,
      );
    });

    test('schedules the next refresh at local midnight', () {
      expect(
        policy.untilNextDay(DateTime(2026, 7, 21, 23, 59, 30)),
        const Duration(seconds: 30),
      );
    });
  });

  group('session request guard', () {
    const guard = HomeSessionRequestGuard();

    test('accepts only the session that started the request', () {
      expect(
        () => guard.ensureCurrent(
          expectedUserId: 'user-a',
          currentUserId: 'user-a',
        ),
        returnsNormally,
      );
    });

    test('discards completion after logout or account switch', () {
      expect(
        () =>
            guard.ensureCurrent(expectedUserId: 'user-a', currentUserId: null),
        throwsStateError,
      );
      expect(
        () => guard.ensureCurrent(
          expectedUserId: 'user-a',
          currentUserId: 'user-b',
        ),
        throwsStateError,
      );
    });
  });
}

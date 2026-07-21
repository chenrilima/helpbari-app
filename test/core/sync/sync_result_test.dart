import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';

void main() {
  test('sync result can refresh only the session that produced it', () {
    final now = DateTime.utc(2026, 7, 21);
    final result = SyncResult(
      startedAt: now,
      completedAt: now,
      repositoriesProcessed: 1,
      pushed: 0,
      pulled: 1,
      deleted: 0,
      conflicts: const [],
      errors: const [],
      userId: 'user-a',
      domainsChanged: const {SyncDomain.water},
    );

    expect(result.belongsTo('user-a'), isTrue);
    expect(result.belongsTo('user-b'), isFalse);
    expect(result.belongsTo(null), isFalse);
    expect(SyncResult.empty(now).belongsTo('user-a'), isFalse);
  });
}

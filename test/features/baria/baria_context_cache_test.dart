import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/baria/application/baria_context_cache.dart';
import 'package:helpbari/features/baria/domain/models/models.dart';

void main() {
  test('returns the same context inside TTL and expires deterministically', () {
    final cache = BariaContextCache();
    final generatedAt = DateTime(2026, 7, 16, 10);
    final context = BariaContext(
      userId: 'user-a',
      generatedAt: generatedAt,
      today: null,
      week: null,
      month: null,
      report: null,
      syncState: const SyncState(),
    );
    cache.write(context);

    expect(
      cache.read(
        userId: 'user-a',
        now: generatedAt.add(const Duration(minutes: 4)),
        maxAge: const Duration(minutes: 5),
      ),
      same(context),
    );
    expect(
      cache.read(
        userId: 'user-b',
        now: generatedAt,
        maxAge: const Duration(minutes: 5),
      ),
      isNull,
    );
    expect(
      cache.read(
        userId: 'user-a',
        now: generatedAt.add(const Duration(minutes: 5)),
        maxAge: const Duration(minutes: 5),
      ),
      isNull,
    );
  });
}

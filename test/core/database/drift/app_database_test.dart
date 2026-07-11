import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/drift_database_providers.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('WaterDao', () {
    test('CRUD is isolated by userId', () async {
      await database.waterDao.upsert(_water(userId: 'user-a', amountMl: 250));
      await database.waterDao.upsert(_water(userId: 'user-b', amountMl: 500));

      final userA = await database.waterDao.getActiveByUser('user-a');
      final userB = await database.waterDao.getActiveByUser('user-b');

      expect(userA.single.amountMl, 250);
      expect(userB.single.amountMl, 500);

      await database.waterDao.deleteByUserAndId('user-a', 'same-id');

      expect(
        await database.waterDao.getByUserAndId('user-a', 'same-id'),
        isNull,
      );
      expect(
        await database.waterDao.getByUserAndId('user-b', 'same-id'),
        isNotNull,
      );
    });

    test('batch inserts records and pending query stays scoped', () async {
      await database.waterDao.upsertAll([
        _water(userId: 'user-a', id: 'a-1'),
        _water(userId: 'user-a', id: 'a-2', syncStatus: 'synced'),
        _water(userId: 'user-b', id: 'b-1'),
      ]);

      final pending = await database.waterDao.getPendingByUser('user-a');

      expect(pending.map((record) => record.id), ['a-1']);
    });

    test('transaction rolls back all writes on failure', () async {
      await expectLater(
        database.waterDao.inTransaction<void>(() async {
          await database.waterDao.upsert(_water(userId: 'user-a', id: 'one'));
          await database.waterDao.upsert(_water(userId: 'user-a', id: 'two'));
          throw StateError('force rollback');
        }),
        throwsStateError,
      );

      expect(await database.waterDao.getActiveByUser('user-a'), isEmpty);
    });
  });

  test('Water indexes are created', () async {
    final indexes = await database
        .customSelect("PRAGMA index_list('water_records')")
        .get();
    final names = indexes.map((row) => row.read<String>('name')).toSet();

    expect(names, contains('water_user_deleted_recorded_idx'));
    expect(names, contains('water_user_sync_updated_idx'));
  });

  test('AppDatabase can be overridden with an in-memory database', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => database)],
    );
    addTearDown(container.dispose);

    final resolvedDatabase = await container.read(appDatabaseProvider.future);
    final dao = await container.read(waterDaoProvider.future);

    expect(identical(resolvedDatabase, database), isTrue);
    await dao.upsert(_water(userId: 'test-user'));
    expect(await dao.getActiveByUser('test-user'), hasLength(1));
  });
}

WaterRecordsCompanion _water({
  required String userId,
  String id = 'same-id',
  int amountMl = 200,
  String syncStatus = 'pendingCreate',
}) {
  final now = DateTime.utc(2026, 7, 11, 12);

  return WaterRecordsCompanion.insert(
    id: id,
    userId: userId,
    amountMl: amountMl,
    recordedAt: now,
    createdAt: now,
    updatedAt: now,
    syncStatus: syncStatus,
  );
}

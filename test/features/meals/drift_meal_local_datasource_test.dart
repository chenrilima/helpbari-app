import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/consistency/meal_local_consistency_checker.dart';
import 'package:helpbari/core/database/drift/cutover/meal_cutover_service.dart';
import 'package:helpbari/core/database/drift/migrations/meal_legacy_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/meals/data/datasources/drift_meal_local_datasource.dart';
import 'package:helpbari/features/meals/data/dtos/meal_dto.dart';
import 'package:helpbari/features/meals/domain/value_objects/value_objects.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 7, 12, 12);
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'CRUD, tombstone, latest updatedAt and anonymous sync isolation',
    () async {
      final local = DriftMealLocalDatasource(
        dao: database.mealDao,
        clock: _Clock(now),
        userId: 'user-1',
      );
      await local.save(_dto(now));
      expect((await local.getAll()).single.name, 'Almoço');
      expect(
        (await local.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingCreate,
      );

      await local.applyRemoteAndMarkSynced(
        _dto(now.add(const Duration(minutes: 1)), name: 'Jantar'),
      );
      expect((await local.getAll()).single.name, 'Jantar');
      expect(
        (await local.getAll()).single.syncMetadata.syncStatus,
        SyncStatus.synced,
      );
      await local.applyRemote(_dto(now, name: 'Antigo'));
      expect((await local.getAll()).single.name, 'Jantar');

      await local.delete('meal-1');
      expect(await local.getAll(), isEmpty);
      expect(
        (await local.pendingSync()).single.syncMetadata.syncStatus,
        SyncStatus.pendingDelete,
      );

      final anonymous = DriftMealLocalDatasource(
        dao: database.mealDao,
        clock: _Clock(now),
        userId: anonymousMealUserId,
      );
      await anonymous.save(_dto(now));
      expect(await anonymous.pendingSync(), isEmpty);
    },
  );

  test(
    'legacy migration preserves storage and cutover is scoped by user',
    () async {
      final storage = _Storage();
      final record = LocalDatabaseRecord(
        metadata: SyncMetadata(
          id: 'legacy-1',
          userId: 'user-1',
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
        ),
        data: {
          'name': 'Sopa',
          'type': 'dinner',
          'mealDate': now.toIso8601String(),
          'notes': null,
          'proteinGrams': 20,
        },
      );
      storage.value = jsonEncode([record.toJson()]);
      final original = storage.value;
      await MealLegacyService(database: database, storage: storage).migrate();
      await MealLegacyService(database: database, storage: storage).migrate();
      expect(await database.mealDao.getActiveByUser('user-1'), hasLength(1));
      expect(storage.value, original);
      expect(
        (await MealLocalConsistencyChecker(
          database: database,
          storage: storage,
        ).check(userId: 'user-1')).consistent,
        isTrue,
      );

      final cutover = MealCutoverService(database: database, storage: storage);
      expect(await cutover.attempt('user-1'), isTrue);
      expect(await cutover.attempt('user-1'), isTrue);
      expect(await cutover.attempt(anonymousMealUserId), isFalse);
      expect(await cutover.isCompleted('user-1'), isTrue);
      expect(await cutover.isCompleted('user-2'), isFalse);
      expect(storage.value, original);
    },
  );

  test('range query filters in Drift and respects limit', () async {
    final local = DriftMealLocalDatasource(
      dao: database.mealDao,
      clock: _Clock(now),
      userId: 'user-1',
    );
    await local.save(_dto(now, id: 'one', mealDate: DateTime(2026, 7, 1)));
    await local.save(_dto(now, id: 'two', mealDate: DateTime(2026, 7, 2)));
    await local.save(_dto(now, id: 'end', mealDate: DateTime(2026, 7, 3)));

    final values = await local.getByPeriod(
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 3),
      limit: 1,
    );

    expect(values.single.id, 'two');
  });
}

MealDto _dto(
  DateTime updatedAt, {
  String name = 'Almoço',
  String id = 'meal-1',
  DateTime? mealDate,
}) => MealDto(
  id: id,
  name: name,
  type: MealType.lunch,
  mealDate: mealDate ?? DateTime.utc(2026, 7, 12),
  notes: 'Teste',
  proteinGrams: 25,
  syncMetadata: SyncMetadata(
    id: id,
    userId: 'user-1',
    createdAt: DateTime.utc(2026, 7, 1),
    updatedAt: updatedAt,
    syncStatus: SyncStatus.pendingCreate,
  ),
);

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

class _Storage implements LocalStorageService {
  String? value;
  final Map<String, String> mirrors = {};
  @override
  bool? getBool(String key) => null;
  @override
  String? getString(String key) =>
      key == mealLegacyStorageKey ? value : mirrors[key];
  @override
  Future<void> setBool(String key, bool value) async {}
  @override
  Future<void> setString(String key, String value) async {
    mirrors[key] = value;
  }
}

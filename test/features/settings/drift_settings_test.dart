import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/shared_preferences_local_database.dart';
import 'package:helpbari/core/database/drift/migrations/settings_legacy_service.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/services/logger_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/settings/data/datasources/drift_settings_local_datasource.dart';
import 'package:helpbari/features/settings/data/datasources/local_settings_datasource.dart';
import 'package:helpbari/features/settings/data/datasources/settings_supabase_datasource.dart';
import 'package:helpbari/features/settings/data/repositories/settings_sync_repository.dart';
import 'package:helpbari/features/settings/data/repositories/drift_settings_repository.dart';
import 'package:helpbari/features/settings/data/dtos/settings_dto.dart';
import 'package:helpbari/features/settings/application/settings_reminder_sync_service.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/vitamins/application/vitamin_reminder_service.dart';
import 'package:helpbari/features/vitamins/domain/entities/entities.dart';
import 'package:helpbari/features/vitamins/domain/repositories/repositories.dart';
import 'package:helpbari/features/vitamins/domain/usecases/vitamin_use_cases.dart';
import 'package:helpbari/features/medications/application/medication_reminder_service.dart';
import 'package:helpbari/features/medications/domain/entities/entities.dart';
import 'package:helpbari/features/medications/domain/repositories/repositories.dart';
import 'package:helpbari/features/medications/domain/usecases/medication_use_cases.dart';
import 'package:helpbari/features/appointments/application/appointment_reminder_service.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/repositories/repositories.dart';
import 'package:helpbari/features/appointments/domain/usecases/use_cases.dart';
import 'package:helpbari/core/services/notifications/notifications.dart';

void main() {
  late AppDatabase database;
  late _Storage storage;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    storage = _Storage();
  });
  tearDown(() => database.close());

  test('persists defaults and upserts per user', () async {
    final first = _datasource(database, 'user-a');
    final second = _datasource(database, 'user-b');
    expect((await first.getSettings()).dailyWaterGoalMl, 2000);
    await first.save(_dto('user-a', 2500));
    await second.save(_dto('user-b', 3000));

    expect((await first.getSettings()).dailyWaterGoalMl, 2500);
    expect((await second.getSettings()).dailyWaterGoalMl, 3000);
    expect(await database.select(database.settingsRecords).get(), hasLength(2));
  });

  test('anonymous never exposes pending sync', () async {
    final datasource = _datasource(database, 'anonymous');
    await datasource.getSettings();
    expect(await datasource.pending(), isEmpty);
  });

  test('latest updatedAt wins and tombstone is applied', () async {
    final datasource = _datasource(database, 'user-a');
    await datasource.save(_dto('user-a', 2200));
    final older = _dto('user-a', 1000, updatedAt: DateTime.utc(2025));
    expect(await datasource.applyRemote(older), isFalse);
    final newer = _dto(
      'user-a',
      2800,
      updatedAt: DateTime.utc(2027),
      deletedAt: DateTime.utc(2027),
      status: SyncStatus.synced,
    );
    expect(await datasource.applyRemoteAndMarkSynced(newer), isTrue);
    final result = await datasource.getSettings();
    expect(result.dailyWaterGoalMl, 2800);
    expect(result.syncMetadata.deletedAt, isNotNull);
  });

  test('cursor is isolated by user', () async {
    final first = _datasource(database, 'user-a');
    final second = _datasource(database, 'user-b');
    final at = DateTime.utc(2026, 7, 12);
    await first.saveCursor(at);
    expect((await first.getLastPullAt())?.toUtc(), at);
    expect(await second.getLastPullAt(), isNull);
  });

  test(
    'migration is idempotent, cutover is marked, and legacy is intact',
    () async {
      final legacy = _dto('user-a', 2600).toRecord().toJson();
      storage.values[SettingsLegacyService.legacyKey] = jsonEncode([legacy]);
      final before = storage.getString(SettingsLegacyService.legacyKey);
      final service = SettingsLegacyService(
        database: database,
        storage: storage,
      );

      final first = await service.migrate();
      final second = await service.migrate();
      final cutover = await service.ensureUserAndAttemptCutover('user-a');

      expect(first.imported, 1);
      expect(second.ignored, 1);
      expect(cutover.completed, isTrue);
      expect(
        await database.select(database.settingsCutovers).get(),
        hasLength(1),
      );
      expect(storage.getString(SettingsLegacyService.legacyKey), before);
    },
  );

  test('migration rolls back records and marker on database failure', () async {
    storage.values[SettingsLegacyService.legacyKey] = jsonEncode([
      _dto('user-a', 2600).toRecord().toJson(),
    ]);
    await database.customStatement('''
      CREATE TRIGGER reject_settings BEFORE INSERT ON settings_records
      BEGIN SELECT RAISE(ABORT, 'forced'); END
    ''');

    await expectLater(
      SettingsLegacyService(database: database, storage: storage).migrate(),
      throwsA(anything),
    );
    expect(await database.select(database.settingsRecords).get(), isEmpty);
    expect(await database.select(database.localMigrations).get(), isEmpty);
  });

  test('post-commit reminder application is idempotent', () async {
    final settingsUseCases = SettingsUseCases(_SettingsRepository());
    final notifications = _Notifications();
    final service = SettingsReminderSyncService(
      vitaminUseCases: VitaminUseCases(_VitaminRepository()),
      vitaminReminders: VitaminReminderService(
        settingsUseCases: settingsUseCases,
        notifications: notifications,
      ),
      medicationUseCases: MedicationUseCases(_MedicationRepository()),
      medicationReminders: MedicationReminderService(
        settingsUseCases: settingsUseCases,
        notifications: notifications,
      ),
      appointmentUseCases: AppointmentUseCases(_AppointmentRepository()),
      appointmentReminders: AppointmentReminderService(
        settingsUseCases: settingsUseCases,
        notifications: notifications,
      ),
    );
    const settings = AppSettings(id: 'user-a');
    expect(await service.applyAfterCommit(settings), isTrue);
    expect(await service.applyAfterCommit(settings), isFalse);
  });

  test('sync repository pushes, pulls and applies remote settings', () async {
    final local = _datasource(database, 'user-a');
    await local.save(_dto('user-a', 2300));
    final remote = _Remote();
    var postCommits = 0;
    final repository = SettingsSyncRepository(
      local: () async => local,
      remote: remote,
      userId: 'user-a',
      afterCommit: (_) async => postCommits++,
    );

    final pending = await repository.pendingOperations();
    await repository.push(pending.single);
    await repository.markSynced(
      pending.single.recordId,
      syncedAt: DateTime.now(),
    );
    expect(remote.upserts, 1);
    expect(await local.pending(), isEmpty);

    remote.pulled = [
      _dto(
        'user-a',
        3100,
        updatedAt: DateTime.utc(2028),
        status: SyncStatus.synced,
      ),
    ];
    final pulled = await repository.pull(updatedAfter: DateTime.utc(2027));
    await repository.applyRemoteAndMarkSynced(
      pulled.single,
      syncedAt: DateTime.now(),
    );
    expect((await local.getSettings()).dailyWaterGoalMl, 3100);
    expect(postCommits, 2);
  });

  test(
    'uses legacy read fallback only before cutover when Drift fails',
    () async {
      final fallback = LocalSettingsDatasource(
        database: SharedPreferencesLocalDatabase(storage),
        clock: const _Clock(),
      );
      await fallback.save(_dto('local-settings', 2700));
      final before = storage.getString(SettingsLegacyService.legacyKey);
      final repository = DriftSettingsRepository(
        datasource: () async => throw StateError('unavailable'),
        fallback: fallback,
        legacy: () async =>
            throw StateError('must not access Drift for fallback'),
        userId: 'user-a',
        logger: _Logger(),
        storage: storage,
      );

      expect((await repository.getSettings()).dailyWaterGoalMl, 2700);
      expect(storage.getString(SettingsLegacyService.legacyKey), before);
    },
  );
}

DriftSettingsLocalDatasource _datasource(AppDatabase database, String userId) =>
    DriftSettingsLocalDatasource(
      dao: database.settingsDao,
      clock: const _Clock(),
      userId: userId,
    );

SettingsDto _dto(
  String userId,
  int goal, {
  DateTime? updatedAt,
  DateTime? deletedAt,
  SyncStatus status = SyncStatus.pendingCreate,
}) {
  final created = DateTime.utc(2026, 1, 1);
  return SettingsDto(
    id: userId,
    dailyWaterGoalMl: goal,
    vitaminRemindersEnabled: true,
    medicationRemindersEnabled: true,
    appointmentRemindersEnabled: true,
    mealTrackingEnabled: true,
    weightUnit: 'kg',
    syncMetadata: SyncMetadata(
      id: userId,
      userId: userId,
      createdAt: created,
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 2),
      deletedAt: deletedAt,
      syncStatus: status,
    ),
  );
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 12);
}

class _Storage implements LocalStorageService {
  final Map<String, Object> values = {};
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  String? getString(String key) => values[key] as String?;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => const AppSettings(id: 'user-a');
  @override
  Future<void> saveSettings(AppSettings settings) async {}
}

class _VitaminRepository implements VitaminRepository {
  @override
  Future<List<Vitamin>> getAll() async => [];
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> save(Vitamin vitamin) async {}
  @override
  Future<void> update(Vitamin vitamin) async {}
}

class _MedicationRepository implements MedicationRepository {
  @override
  Future<List<Medication>> getAll() async => [];
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> save(Medication medication) async {}
  @override
  Future<void> update(Medication medication) async {}
}

class _AppointmentRepository implements AppointmentRepository {
  @override
  Future<List<Appointment>> getAll() async => [];
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> save(Appointment appointment) async {}
  @override
  Future<void> update(Appointment appointment) async {}
}

class _Notifications implements LocalNotificationService {
  @override
  Future<void> cancel(String key) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> cancelPayload(LocalNotificationPayload payload) async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<void> reschedule(
    Iterable<LocalNotificationSchedule> schedules,
  ) async {}
  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) async {}
  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) async {}
  @override
  Future<void> update(LocalNotificationSchedule schedule) async {}
}

class _Remote implements SettingsRemoteDatasource {
  int upserts = 0;
  List<SettingsDto> pulled = [];
  @override
  Future<SettingsDto> upsert(SettingsDto value, String userId) async {
    upserts++;
    return _dto(
      userId,
      value.dailyWaterGoalMl,
      updatedAt: value.syncMetadata.updatedAt.add(const Duration(seconds: 1)),
      status: SyncStatus.synced,
    );
  }

  @override
  Future<List<SettingsDto>> pull(String userId, DateTime? updatedAfter) async =>
      pulled;
}

class _Logger implements LoggerService {
  @override
  void info(String message) {}
  @override
  void warning(String message) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

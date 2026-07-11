import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/bootstrap/drift_bootstrap_service.dart';
import 'package:helpbari/core/database/drift/migrations/water_local_migration_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/services/logger_service.dart';
import 'package:helpbari/core/sync/sync_metadata.dart';
import 'package:helpbari/core/sync/sync_status.dart';

void main() {
  test(
    'Drift failure returns degraded result and closes the database',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      await database.customStatement('''
      CREATE TRIGGER reject_bootstrap BEFORE INSERT ON water_records
      BEGIN
        SELECT RAISE(ABORT, 'forced failure');
      END
    ''');
      final storage = _BootstrapStorage()..writeWaterRecord();
      final logger = _RecordingLogger();
      final service = DriftBootstrapService(
        storage: storage,
        logger: logger,
        databaseFactory: () async => database,
      );

      final result = await service.initialize();

      expect(result.isAvailable, isFalse);
      expect(result.database, isNull);
      expect(logger.warnings, hasLength(1));
      expect(logger.warnings.single, isNot(contains('forced failure')));
      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );
    },
  );
}

class _BootstrapStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  void writeWaterRecord() {
    final createdAt = DateTime.utc(2026, 1, 1);
    final record = LocalDatabaseRecord(
      metadata: SyncMetadata(
        id: 'water-1',
        userId: 'user-a',
        createdAt: createdAt,
        updatedAt: createdAt,
        syncStatus: SyncStatus.pendingCreate,
      ),
      data: {'amountInMl': 200, 'recordedAt': createdAt.toIso8601String()},
    );
    _values[WaterLocalMigrationService.legacyStorageKey] = jsonEncode([
      record.toJson(),
    ]);
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
}

class _RecordingLogger implements LoggerService {
  final List<String> infos = [];
  final List<String> warnings = [];
  final List<String> errors = [];

  @override
  void info(String message) => infos.add(message);

  @override
  void warning(String message) => warnings.add(message);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    errors.add(message);
  }
}

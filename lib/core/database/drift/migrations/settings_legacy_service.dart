import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../../../../features/settings/data/dtos/settings_dto.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

class SettingsLegacyService {
  const SettingsLegacyService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;

  static const legacyKey = 'local_database.collection.settings';
  static const migrationKey = 'shared_preferences.settings.v1';
  static const cutoverKey = 'settings.drift.cutover';
  static const anonymousUserId = 'anonymous';
  static const _mirrorPrefix = 'core.settings.cutover.v1';

  final AppDatabase _database;
  final LocalStorageService _storage;

  Future<SettingsMigrationReport> migrate() async {
    final snapshot = _read();
    var imported = 0;
    var updated = 0;
    var ignored = 0;
    await _database.transaction(() async {
      final cutovers =
          (await _database.select(_database.settingsCutovers).get())
              .map((row) => row.userId)
              .toSet();
      for (final item in snapshot.records.where(
        (item) => !cutovers.contains(item.userId),
      )) {
        final existing = await _database.settingsDao.getByUser(item.userId);
        if (existing == null) {
          await _database.settingsDao.upsert(item.companion);
          imported++;
        } else if (item.updatedAt.isAfter(existing.updatedAt)) {
          await _database.settingsDao.upsert(item.companion);
          updated++;
        } else {
          ignored++;
        }
      }
      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(snapshot.checksum),
              importedCount: Value(snapshot.records.length),
            ),
          );
    });
    return SettingsMigrationReport(
      read: snapshot.read,
      invalid: snapshot.invalid,
      imported: imported,
      updated: updated,
      ignored: ignored,
      checksum: snapshot.checksum,
    );
  }

  Future<SettingsCutoverResult> ensureUserAndAttemptCutover(
    String userId,
  ) async {
    if (userId == anonymousUserId) {
      return const SettingsCutoverResult(false, 'anonymous');
    }
    final existingMarker =
        await (_database.select(_database.settingsCutovers)..where(
              (row) =>
                  row.migrationKey.equals(cutoverKey) &
                  row.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (existingMarker != null) {
      await _writeMirror(
        userId,
        existingMarker.checksum,
        existingMarker.recordCount,
      );
      return const SettingsCutoverResult(true, null);
    }
    final migration = await (_database.select(
      _database.localMigrations,
    )..where((row) => row.migrationKey.equals(migrationKey))).getSingleOrNull();
    if (migration == null) {
      return const SettingsCutoverResult(false, 'migration_missing');
    }
    final snapshot = _read();
    if (snapshot.invalid > 0) {
      return const SettingsCutoverResult(false, 'invalid_legacy');
    }

    var current = await _database.settingsDao.getByUser(userId);
    if (current == null) {
      final now = DateTime.now().toUtc();
      await _database.settingsDao.upsert(
        SettingsRecordsCompanion.insert(
          id: userId,
          userId: userId,
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pendingCreate',
        ),
      );
      current = await _database.settingsDao.getByUser(userId);
    }
    final legacy = snapshot.records
        .where((item) => item.userId == userId)
        .toList();
    if (legacy.isNotEmpty && !_same(legacy.single, current!)) {
      return const SettingsCutoverResult(false, 'not_converged');
    }
    final normalized = _NormalizedSettings.fromDrift(current!);
    final checksum = _checksum([normalized]);
    await _database.transaction(() async {
      await _database
          .into(_database.settingsCutovers)
          .insertOnConflictUpdate(
            SettingsCutoversCompanion.insert(
              migrationKey: cutoverKey,
              version: 1,
              userId: userId,
              completedAt: DateTime.now().toUtc(),
              checksum: checksum,
              recordCount: 1,
              databaseSchemaVersion: _database.schemaVersion,
            ),
          );
    });
    await _writeMirror(userId, checksum, 1);
    return const SettingsCutoverResult(true, null);
  }

  bool hasCutoverMirror(String userId) => hasCutoverMirrorFor(_storage, userId);

  static bool hasCutoverMirrorFor(LocalStorageService storage, String userId) =>
      storage.getString('$_mirrorPrefix.$userId') != null;

  _SettingsSnapshot _read() {
    final raw = _storage.getString(legacyKey);
    if (raw == null || raw.isEmpty) return _SettingsSnapshot.empty();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return _SettingsSnapshot.invalid();
      final records = <_NormalizedSettings>[];
      var invalid = 0;
      for (final value in decoded) {
        try {
          final record = LocalDatabaseRecord.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          records.add(_NormalizedSettings.fromLegacy(record));
        } catch (_) {
          invalid++;
        }
      }
      return _SettingsSnapshot(
        decoded.length,
        invalid,
        records,
        _checksum(records),
      );
    } catch (_) {
      return _SettingsSnapshot.invalid();
    }
  }

  bool _same(_NormalizedSettings legacy, SettingsRecord drift) =>
      jsonEncode(legacy.content) ==
      jsonEncode(_NormalizedSettings.fromDrift(drift).content);

  static String _checksum(List<_NormalizedSettings> records) {
    records.sort(
      (a, b) => '${a.userId}:${a.id}'.compareTo('${b.userId}:${b.id}'),
    );
    return sha256
        .convert(
          utf8.encode(jsonEncode(records.map((e) => e.content).toList())),
        )
        .toString();
  }

  Future<void> _writeMirror(String userId, String checksum, int count) =>
      _storage.setString(
        '$_mirrorPrefix.$userId',
        jsonEncode({'version': 1, 'checksum': checksum, 'count': count}),
      );
}

class _NormalizedSettings {
  const _NormalizedSettings({
    required this.id,
    required this.userId,
    required this.dto,
  });
  factory _NormalizedSettings.fromLegacy(LocalDatabaseRecord record) {
    final dto = SettingsDto.fromRecord(record);
    final raw = record.metadata.userId;
    return _NormalizedSettings(
      id: dto.id,
      userId: raw == null || raw.trim().isEmpty
          ? SettingsLegacyService.anonymousUserId
          : raw,
      dto: dto,
    );
  }
  factory _NormalizedSettings.fromDrift(SettingsRecord row) =>
      _NormalizedSettings(
        id: row.id,
        userId: row.userId,
        dto: SettingsDto.fromDrift(row),
      );
  final String id;
  final String userId;
  final SettingsDto dto;
  DateTime get updatedAt => dto.syncMetadata.updatedAt;
  Map<String, Object?> get content => {
    'userId': userId,
    'id': id,
    'dailyWaterGoalMl': dto.dailyWaterGoalMl,
    'vitaminRemindersEnabled': dto.vitaminRemindersEnabled,
    'medicationRemindersEnabled': dto.medicationRemindersEnabled,
    'appointmentRemindersEnabled': dto.appointmentRemindersEnabled,
    'mealTrackingEnabled': dto.mealTrackingEnabled,
    'weightUnit': dto.weightUnit,
    'updatedAt': dto.syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deletedAt': dto.syncMetadata.deletedAt?.toUtc().toIso8601String(),
    'syncStatus': dto.syncMetadata.syncStatus.name,
  };
  SettingsRecordsCompanion get companion => dto.toDrift(userId: userId);
}

class _SettingsSnapshot {
  const _SettingsSnapshot(this.read, this.invalid, this.records, this.checksum);
  factory _SettingsSnapshot.empty() =>
      _SettingsSnapshot(0, 0, [], SettingsLegacyService._checksum([]));
  factory _SettingsSnapshot.invalid() =>
      _SettingsSnapshot(1, 1, [], SettingsLegacyService._checksum([]));
  final int read;
  final int invalid;
  final List<_NormalizedSettings> records;
  final String checksum;
}

class SettingsMigrationReport {
  const SettingsMigrationReport({
    required this.read,
    required this.invalid,
    required this.imported,
    required this.updated,
    required this.ignored,
    required this.checksum,
  });
  final int read, invalid, imported, updated, ignored;
  final String checksum;
}

class SettingsCutoverResult {
  const SettingsCutoverResult(this.completed, this.blockedReason);
  final bool completed;
  final String? blockedReason;
}

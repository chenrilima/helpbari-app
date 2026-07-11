import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../../../../features/profile/data/dtos/profile_dto.dart';
import '../app_database.dart';

class ProfileLegacyService {
  const ProfileLegacyService({required this.database, required this.storage});
  static const legacyKey = 'local_database.collection.profiles';
  static const migrationKey = 'shared_preferences.profile.v1';
  static const cutoverKey = 'profile.drift.cutover';
  static const anonymousUserId = 'anonymous';
  static const _mirrorPrefix = 'core.profile.cutover.v1';
  final AppDatabase database;
  final LocalStorageService storage;

  Future<ProfileMigrationReport> migrate() async {
    final snapshot = _read();
    var imported = 0;
    var updated = 0;
    var ignored = 0;
    await database.transaction(() async {
      for (final item in snapshot.records) {
        final existing = await database.profileDao.getByUser(item.userId);
        if (existing == null) {
          await database.profileDao.upsert(
            item.dto.toDrift(userId: item.userId),
          );
          imported++;
        } else if (item.dto.syncMetadata.updatedAt.isAfter(
          existing.updatedAt,
        )) {
          await database.profileDao.upsert(
            item.dto.toDrift(userId: item.userId),
          );
          updated++;
        } else {
          ignored++;
        }
      }
      await database
          .into(database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(snapshot.checksum),
              importedCount: Value(snapshot.records.length),
            ),
          );
    });
    return ProfileMigrationReport(
      read: snapshot.read,
      invalid: snapshot.invalid,
      imported: imported,
      updated: updated,
      ignored: ignored,
      checksum: snapshot.checksum,
    );
  }

  Future<ProfileCutoverResult> ensureUserAndAttemptCutover(
    String userId,
  ) async {
    if (userId == anonymousUserId) {
      return const ProfileCutoverResult(false, 'anonymous');
    }
    final existing =
        await (database.select(database.profileCutovers)..where(
              (r) =>
                  r.migrationKey.equals(cutoverKey) & r.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (existing != null) {
      await _mirror(userId, existing.checksum, existing.recordCount);
      return const ProfileCutoverResult(true, null);
    }
    final migration = await (database.select(
      database.localMigrations,
    )..where((r) => r.migrationKey.equals(migrationKey))).getSingleOrNull();
    if (migration == null) {
      return const ProfileCutoverResult(false, 'migration_missing');
    }
    final snapshot = _read();
    if (snapshot.invalid > 0) {
      return const ProfileCutoverResult(false, 'invalid_legacy');
    }
    final legacy = snapshot.records.where((r) => r.userId == userId).toList();
    final drift = await database.profileDao.getByUser(userId);
    if (legacy.isNotEmpty &&
        (drift == null ||
            !legacy.single.dto.syncMetadata.updatedAt.isAtSameMomentAs(
              drift.updatedAt,
            ))) {
      return const ProfileCutoverResult(false, 'not_converged');
    }
    final checksum = sha256
        .convert(
          utf8.encode(
            jsonEncode(
              drift == null
                  ? []
                  : [ProfileDto.fromDrift(drift).toRecord().toJson()],
            ),
          ),
        )
        .toString();
    await database
        .into(database.profileCutovers)
        .insertOnConflictUpdate(
          ProfileCutoversCompanion.insert(
            migrationKey: cutoverKey,
            version: 1,
            userId: userId,
            completedAt: DateTime.now().toUtc(),
            checksum: checksum,
            recordCount: drift == null ? 0 : 1,
            databaseSchemaVersion: database.schemaVersion,
          ),
        );
    await _mirror(userId, checksum, drift == null ? 0 : 1);
    return const ProfileCutoverResult(true, null);
  }

  bool hasCutoverMirror(String userId) =>
      storage.getString('$_mirrorPrefix.$userId') != null;

  _Snapshot _read() {
    final raw = storage.getString(legacyKey);
    if (raw == null || raw.isEmpty) return const _Snapshot(0, 0, [], 'empty');
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const _Snapshot(0, 1, [], 'invalid');
      final records = <_LegacyProfile>[];
      var invalid = 0;
      for (final value in decoded) {
        try {
          final record = LocalDatabaseRecord.fromJson(
            Map<String, dynamic>.from(value as Map),
          );
          final dto = ProfileDto.fromRecord(record);
          final rawUser = record.metadata.userId;
          records.add(
            _LegacyProfile(
              rawUser == null || rawUser.isEmpty ? anonymousUserId : rawUser,
              dto,
            ),
          );
        } catch (_) {
          invalid++;
        }
      }
      final checksum = sha256.convert(utf8.encode(raw)).toString();
      return _Snapshot(decoded.length, invalid, records, checksum);
    } catch (_) {
      return const _Snapshot(0, 1, [], 'invalid');
    }
  }

  Future<void> _mirror(String userId, String checksum, int count) =>
      storage.setString(
        '$_mirrorPrefix.$userId',
        jsonEncode({'version': 1, 'checksum': checksum, 'count': count}),
      );
}

class ProfileMigrationReport {
  const ProfileMigrationReport({
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

class ProfileCutoverResult {
  const ProfileCutoverResult(this.completed, this.blockedReason);
  final bool completed;
  final String? blockedReason;
}

class _LegacyProfile {
  const _LegacyProfile(this.userId, this.dto);
  final String userId;
  final ProfileDto dto;
}

class _Snapshot {
  const _Snapshot(this.read, this.invalid, this.records, this.checksum);
  final int read, invalid;
  final List<_LegacyProfile> records;
  final String checksum;
}

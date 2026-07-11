import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';
import 'water_local_migration_report.dart';

class WaterLocalMigrationService {
  const WaterLocalMigrationService({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;

  static const migrationKey = 'shared_preferences.water_records.v1';
  static const legacyStorageKey = 'local_database.collection.water_records';
  static const anonymousUserId = 'anonymous';

  final AppDatabase _database;
  final LocalStorageService _storage;

  Future<WaterLocalMigrationReport> migrate() async {
    final decoded = _decodeLegacyCollection(
      _storage.getString(legacyStorageKey),
    );
    final candidates = <_WaterMigrationCandidate>[];
    var invalid = decoded.invalid;

    for (final item in decoded.items) {
      try {
        candidates.add(_candidateFromJson(item));
      } catch (_) {
        invalid++;
      }
    }

    candidates.sort(_compareCandidates);
    final checksum = _checksum(candidates);
    var imported = 0;
    var updated = 0;
    var ignored = 0;

    await _database.transaction(() async {
      for (final candidate in candidates) {
        final existing =
            await (_database.select(_database.waterRecords)..where(
                  (row) =>
                      row.userId.equals(candidate.userId) &
                      row.id.equals(candidate.record.id),
                ))
                .getSingleOrNull();

        if (existing == null) {
          await _database
              .into(_database.waterRecords)
              .insert(candidate.companion);
          imported++;
        } else if (candidate.record.metadata.updatedAt.isAfter(
          existing.updatedAt,
        )) {
          await _database
              .into(_database.waterRecords)
              .insertOnConflictUpdate(candidate.companion);
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
              sourceChecksum: Value(checksum),
              importedCount: Value(candidates.length),
            ),
          );
    });

    return WaterLocalMigrationReport(
      read: decoded.total,
      imported: imported,
      updated: updated,
      ignored: ignored,
      invalid: invalid,
      anonymous: candidates.where((item) => item.isAnonymous).length,
      checksum: checksum,
    );
  }

  _DecodedCollection _decodeLegacyCollection(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const _DecodedCollection(items: [], total: 0, invalid: 0);
    }

    try {
      final value = jsonDecode(raw);
      if (value is! List) {
        return const _DecodedCollection(items: [], total: 1, invalid: 1);
      }

      final items = <Map<String, dynamic>>[];
      var invalid = 0;
      for (final item in value) {
        if (item is Map) {
          items.add(Map<String, dynamic>.from(item));
        } else {
          invalid++;
        }
      }
      return _DecodedCollection(
        items: items,
        total: value.length,
        invalid: invalid,
      );
    } catch (_) {
      return const _DecodedCollection(items: [], total: 1, invalid: 1);
    }
  }

  _WaterMigrationCandidate _candidateFromJson(Map<String, dynamic> json) {
    final record = LocalDatabaseRecord.fromJson(json);
    final amountMl = record.data['amountInMl'];
    final recordedAt = record.data['recordedAt'];
    if (record.id.isEmpty || amountMl is! int || amountMl <= 0) {
      throw const FormatException('Invalid water record');
    }
    if (recordedAt is! String || recordedAt.isEmpty) {
      throw const FormatException('Invalid recordedAt');
    }

    final parsedRecordedAt = DateTime.parse(recordedAt);
    final rawUserId = record.metadata.userId;
    final isAnonymous = rawUserId == null || rawUserId.trim().isEmpty;
    final userId = isAnonymous ? anonymousUserId : rawUserId.trim();
    final failedStatus = record.data['_failedSyncStatus'];

    return _WaterMigrationCandidate(
      record: record,
      userId: userId,
      isAnonymous: isAnonymous,
      amountMl: amountMl,
      recordedAt: parsedRecordedAt,
      previousSyncStatus: failedStatus is String && failedStatus.isNotEmpty
          ? failedStatus
          : null,
    );
  }

  int _compareCandidates(
    _WaterMigrationCandidate a,
    _WaterMigrationCandidate b,
  ) {
    final userComparison = a.userId.compareTo(b.userId);
    if (userComparison != 0) return userComparison;
    final idComparison = a.record.id.compareTo(b.record.id);
    if (idComparison != 0) return idComparison;
    final updatedAtComparison = a.record.metadata.updatedAt.compareTo(
      b.record.metadata.updatedAt,
    );
    if (updatedAtComparison != 0) return updatedAtComparison;
    return jsonEncode(a.normalized).compareTo(jsonEncode(b.normalized));
  }

  String _checksum(List<_WaterMigrationCandidate> candidates) {
    final normalized = candidates
        .map((candidate) => candidate.normalized)
        .toList();
    return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
  }
}

class _WaterMigrationCandidate {
  const _WaterMigrationCandidate({
    required this.record,
    required this.userId,
    required this.isAnonymous,
    required this.amountMl,
    required this.recordedAt,
    required this.previousSyncStatus,
  });

  final LocalDatabaseRecord record;
  final String userId;
  final bool isAnonymous;
  final int amountMl;
  final DateTime recordedAt;
  final String? previousSyncStatus;

  WaterRecordsCompanion get companion => WaterRecordsCompanion.insert(
    id: record.id,
    userId: userId,
    amountMl: amountMl,
    recordedAt: recordedAt,
    createdAt: record.metadata.createdAt,
    updatedAt: record.metadata.updatedAt,
    deletedAt: Value(record.metadata.deletedAt),
    syncStatus: record.metadata.syncStatus.name,
    previousSyncStatus: Value(previousSyncStatus),
  );

  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': record.id,
    'amountMl': amountMl,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'createdAt': record.metadata.createdAt.toUtc().toIso8601String(),
    'updatedAt': record.metadata.updatedAt.toUtc().toIso8601String(),
    'deletedAt': record.metadata.deletedAt?.toUtc().toIso8601String(),
    'syncStatus': record.metadata.syncStatus.name,
    'previousSyncStatus': previousSyncStatus,
  };
}

class _DecodedCollection {
  const _DecodedCollection({
    required this.items,
    required this.total,
    required this.invalid,
  });

  final List<Map<String, dynamic>> items;
  final int total;
  final int invalid;
}

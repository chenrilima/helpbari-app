import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/local_storage_service.dart';
import '../../local_database_record.dart';
import '../app_database.dart';

const waterLegacyStorageKey = 'local_database.collection.water_records';
const anonymousWaterUserId = 'anonymous';

class WaterLocalSnapshot {
  const WaterLocalSnapshot({
    required this.records,
    required this.read,
    required this.invalid,
  });

  final List<NormalizedWaterRecord> records;
  final int read;
  final int invalid;

  int get valid => records.length;

  Set<String> get userIds => records.map((record) => record.userId).toSet();

  String checksumForUser(String userId) => normalizedWaterChecksum(
    records.where((record) => record.userId == userId),
  );
}

class WaterLegacySnapshotReader {
  const WaterLegacySnapshotReader(this._storage);

  final LocalStorageService _storage;

  WaterLocalSnapshot read() {
    final decoded = _decodeCollection(
      _storage.getString(waterLegacyStorageKey),
    );
    final records = <NormalizedWaterRecord>[];
    var invalid = decoded.invalid;

    for (final item in decoded.items) {
      try {
        records.add(NormalizedWaterRecord.fromLegacyJson(item));
      } catch (_) {
        invalid++;
      }
    }

    records.sort(compareNormalizedWaterRecords);
    return WaterLocalSnapshot(
      records: List.unmodifiable(records),
      read: decoded.total,
      invalid: invalid,
    );
  }

  _DecodedCollection _decodeCollection(String? raw) {
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
}

class NormalizedWaterRecord {
  const NormalizedWaterRecord({
    required this.userId,
    required this.id,
    required this.amountMl,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
    required this.previousSyncStatus,
  });

  factory NormalizedWaterRecord.fromLegacyJson(Map<String, dynamic> json) {
    final record = LocalDatabaseRecord.fromJson(json);
    final amountMl = record.data['amountInMl'];
    final recordedAt = record.data['recordedAt'];
    if (record.id.isEmpty || amountMl is! int || amountMl <= 0) {
      throw const FormatException('Invalid water record');
    }
    if (recordedAt is! String || recordedAt.isEmpty) {
      throw const FormatException('Invalid recordedAt');
    }

    final rawUserId = record.metadata.userId;
    final userId = rawUserId == null || rawUserId.trim().isEmpty
        ? anonymousWaterUserId
        : rawUserId.trim();
    final failedStatus = record.data['_failedSyncStatus'];
    return NormalizedWaterRecord(
      userId: userId,
      id: record.id,
      amountMl: amountMl,
      recordedAt: DateTime.parse(recordedAt),
      createdAt: record.metadata.createdAt,
      updatedAt: record.metadata.updatedAt,
      deletedAt: record.metadata.deletedAt,
      syncStatus: record.metadata.syncStatus.name,
      previousSyncStatus: failedStatus is String && failedStatus.isNotEmpty
          ? failedStatus
          : null,
    );
  }

  factory NormalizedWaterRecord.fromDrift(WaterRecord record) {
    return NormalizedWaterRecord(
      userId: record.userId,
      id: record.id,
      amountMl: record.amountMl,
      recordedAt: record.recordedAt,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      deletedAt: record.deletedAt,
      syncStatus: record.syncStatus,
      previousSyncStatus: record.previousSyncStatus,
    );
  }

  final String userId;
  final String id;
  final int amountMl;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final String? previousSyncStatus;

  bool get isAnonymous => userId == anonymousWaterUserId;

  String get key => '$userId:$id';

  WaterRecordsCompanion get companion => WaterRecordsCompanion.insert(
    id: id,
    userId: userId,
    amountMl: amountMl,
    recordedAt: recordedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    syncStatus: syncStatus,
    previousSyncStatus: Value(previousSyncStatus),
  );

  Map<String, Object?> get normalized => {
    'userId': userId,
    'id': id,
    'amountMl': amountMl,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
    'syncStatus': syncStatus,
    'previousSyncStatus': previousSyncStatus,
  };

  Map<String, Object?> get contentNormalized => {
    'amountMl': amountMl,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'previousSyncStatus': previousSyncStatus,
  };
}

int compareNormalizedWaterRecords(
  NormalizedWaterRecord a,
  NormalizedWaterRecord b,
) {
  final userComparison = a.userId.compareTo(b.userId);
  if (userComparison != 0) return userComparison;
  final idComparison = a.id.compareTo(b.id);
  if (idComparison != 0) return idComparison;
  final updatedComparison = a.updatedAt.compareTo(b.updatedAt);
  if (updatedComparison != 0) return updatedComparison;
  return jsonEncode(a.normalized).compareTo(jsonEncode(b.normalized));
}

String normalizedWaterChecksum(Iterable<NormalizedWaterRecord> records) {
  final sorted = records.toList()..sort(compareNormalizedWaterRecords);
  return sha256
      .convert(
        utf8.encode(
          jsonEncode(sorted.map((record) => record.normalized).toList()),
        ),
      )
      .toString();
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

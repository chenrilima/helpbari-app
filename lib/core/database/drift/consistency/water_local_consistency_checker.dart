import 'dart:convert';

import '../../../services/local_storage_service.dart';
import '../app_database.dart';
import 'water_local_consistency_report.dart';
import 'water_local_snapshot.dart';

class WaterLocalConsistencyChecker {
  const WaterLocalConsistencyChecker({
    required AppDatabase database,
    required LocalStorageService storage,
  }) : _database = database,
       _storage = storage;

  final AppDatabase _database;
  final LocalStorageService _storage;

  Future<WaterLocalConsistencyReport> check() async {
    final legacy = WaterLegacySnapshotReader(_storage).read();
    final driftRows = await _database.select(_database.waterRecords).get();
    final drift = driftRows.map(NormalizedWaterRecord.fromDrift).toList()
      ..sort(compareNormalizedWaterRecords);
    final users = {
      ...legacy.userIds,
      ...drift.map((record) => record.userId),
    }.toList()..sort();
    final issues = <WaterConsistencyIssue>[];

    for (final userId in users) {
      final legacyById = {
        for (final record in legacy.records.where(
          (item) => item.userId == userId,
        ))
          record.id: record,
      };
      final driftById = {
        for (final record in drift.where((item) => item.userId == userId))
          record.id: record,
      };
      final ids = {...legacyById.keys, ...driftById.keys}.toList()..sort();

      for (final id in ids) {
        final legacyRecord = legacyById[id];
        final driftRecord = driftById[id];
        if (legacyRecord == null) {
          issues.add(
            WaterConsistencyIssue(
              userId: userId,
              recordId: id,
              types: const [WaterConsistencyIssueType.extraInDrift],
            ),
          );
          continue;
        }
        if (driftRecord == null) {
          issues.add(
            WaterConsistencyIssue(
              userId: userId,
              recordId: id,
              types: const [WaterConsistencyIssueType.missingInDrift],
            ),
          );
          continue;
        }

        final types = <WaterConsistencyIssueType>[];
        if (jsonEncode(legacyRecord.contentNormalized) !=
            jsonEncode(driftRecord.contentNormalized)) {
          types.add(WaterConsistencyIssueType.contentDivergent);
        }
        if (_instant(legacyRecord.deletedAt) !=
            _instant(driftRecord.deletedAt)) {
          types.add(WaterConsistencyIssueType.tombstoneDivergent);
        }
        if (legacyRecord.syncStatus != driftRecord.syncStatus) {
          types.add(WaterConsistencyIssueType.syncStatusDivergent);
        }
        if (types.isNotEmpty) {
          issues.add(
            WaterConsistencyIssue(userId: userId, recordId: id, types: types),
          );
        }
      }
    }

    final checksums = {
      for (final userId in users)
        userId: WaterUserChecksums(
          legacy: normalizedWaterChecksum(
            legacy.records.where((record) => record.userId == userId),
          ),
          drift: normalizedWaterChecksum(
            drift.where((record) => record.userId == userId),
          ),
        ),
    };
    final missing = issues
        .where(
          (issue) =>
              issue.types.contains(WaterConsistencyIssueType.missingInDrift),
        )
        .length;
    final extra = issues
        .where(
          (issue) =>
              issue.types.contains(WaterConsistencyIssueType.extraInDrift),
        )
        .length;
    final divergent = issues.length - missing - extra;

    return WaterLocalConsistencyReport(
      usersAnalyzed: users,
      legacyRecords: legacy.valid,
      driftRecords: drift.length,
      missingInDrift: missing,
      extraInDrift: extra,
      divergent: divergent,
      consistent:
          issues.isEmpty && checksums.values.every((item) => item.matches),
      checksums: Map.unmodifiable(checksums),
      issues: List.unmodifiable(issues),
    );
  }

  int? _instant(DateTime? value) => value?.toUtc().microsecondsSinceEpoch;
}

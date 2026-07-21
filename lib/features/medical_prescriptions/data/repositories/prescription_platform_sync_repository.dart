import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/sync/sync.dart';

class PrescriptionPlatformSyncRepository
    implements SyncableRepository, AppendOnlySyncRepository {
  const PrescriptionPlatformSyncRepository({
    required this.database,
    required this.remote,
    required this.userId,
  });

  final AppDatabase database;
  final SupabaseDatabase remote;
  final String userId;
  static const key = 'prescription_platform';
  static const _tables = <String>[
    'prescription_versions',
    'prescription_reviews',
    'treatment_proposals',
    'prescription_routine_links',
  ];

  @override
  String get syncKey => key;

  @override
  bool isAppendOnly(SyncOperation operation) =>
      operation.payload['table'] == 'prescription_reviews' ||
      (operation.payload['table'] == 'prescription_versions' &&
          (operation.payload['row'] as Map)['status'] == 'confirmed');

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    final result = <SyncOperation>[];
    for (final table in _tables) {
      final rows = await database
          .customSelect(
            'SELECT * FROM ${_localTable(table)} WHERE user_id = ? AND sync_status <> ?',
            variables: [
              Variable<String>(userId),
              const Variable<String>('synced'),
            ],
          )
          .get();
      result.addAll(rows.map((row) => _operation(table, row.data)));
    }
    result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return result;
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final parts = recordId.split('|');
    if (parts.length != 2 || !_tables.contains(parts.first)) return null;
    final rows = await database
        .customSelect(
          'SELECT * FROM ${_localTable(parts.first)} WHERE user_id = ? AND id = ?',
          variables: [Variable<String>(userId), Variable<String>(parts.last)],
        )
        .get();
    return rows.isEmpty ? null : _operation(parts.first, rows.single.data);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final table = operation.payload['table'] as String;
    final row = Map<String, dynamic>.from(operation.payload['row'] as Map);
    await remote.run(
      operation: 'upsert',
      table: table,
      request: (query) => query.upsert(row),
    );
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async {
    final result = <SyncOperation>[];
    for (final table in _tables) {
      final rows = await remote.run(
        operation: 'select',
        table: table,
        request: (query) async {
          var request = query.select().eq('user_id', userId);
          if (updatedAfter != null) {
            request = request.gt(
              'updated_at',
              updatedAfter.toUtc().toIso8601String(),
            );
          }
          return request.order('updated_at');
        },
      );
      result.addAll(
        rows.map((row) => _operation(table, Map<String, Object?>.from(row))),
      );
    }
    return result;
  }

  @override
  Future<void> applyRemote(SyncOperation operation) =>
      _apply(operation, markSynced: true);

  Future<void> _apply(
    SyncOperation operation, {
    required bool markSynced,
  }) async {
    final table = operation.payload['table'] as String;
    final row = Map<String, dynamic>.from(operation.payload['row'] as Map);
    if (row['user_id'] != userId) return;
    final status = markSynced
        ? 'synced'
        : row['sync_status'] as String? ?? 'synced';
    switch (table) {
      case 'prescription_versions':
        await database
            .into(database.prescriptionVersionRecords)
            .insertOnConflictUpdate(
              PrescriptionVersionRecordsCompanion.insert(
                id: row['id'] as String,
                userId: userId,
                prescriptionId: row['prescription_id'] as String,
                revision: row['revision'] as int,
                status: row['status'] as String,
                snapshotJson: _json(row['snapshot']),
                sourceProcessingId: Value(
                  row['source_processing_id'] as String?,
                ),
                submittedAt: Value(_date(row['submitted_at'])),
                confirmedAt: Value(_date(row['confirmed_at'])),
                createdAt: _date(row['created_at'])!,
                updatedAt: _date(row['updated_at'])!,
                deletedAt: Value(_date(row['deleted_at'])),
                syncStatus: status,
              ),
            );
        return;
      case 'prescription_reviews':
        await database
            .into(database.prescriptionReviewRecords)
            .insert(
              PrescriptionReviewRecordsCompanion.insert(
                id: row['id'] as String,
                userId: userId,
                prescriptionId: row['prescription_id'] as String,
                versionId: row['version_id'] as String,
                decision: row['decision'] as String,
                actor: row['actor'] as String,
                fieldDecisionsJson: _json(row['field_decisions']),
                note: Value(row['note'] as String?),
                createdAt: _date(row['created_at'])!,
                updatedAt: _date(row['updated_at'])!,
                deletedAt: Value(_date(row['deleted_at'])),
                syncStatus: status,
              ),
              mode: InsertMode.insertOrIgnore,
            );
        return;
      case 'treatment_proposals':
        await database
            .into(database.treatmentProposalRecords)
            .insertOnConflictUpdate(
              TreatmentProposalRecordsCompanion.insert(
                id: row['id'] as String,
                userId: userId,
                prescriptionId: row['prescription_id'] as String,
                prescriptionVersionId: row['prescription_version_id'] as String,
                prescriptionItemId: row['prescription_item_id'] as String,
                decision: row['decision'] as String,
                draftJson: _json(row['draft']),
                targetRoutineId: Value(row['target_routine_id'] as String?),
                resultingPlanId: Value(row['resulting_plan_id'] as String?),
                confirmedAt: Value(_date(row['confirmed_at'])),
                createdAt: _date(row['created_at'])!,
                updatedAt: _date(row['updated_at'])!,
                deletedAt: Value(_date(row['deleted_at'])),
                syncStatus: status,
              ),
            );
        return;
      case 'prescription_routine_links':
        await database
            .into(database.prescriptionRoutineLinkRecords)
            .insertOnConflictUpdate(
              PrescriptionRoutineLinkRecordsCompanion.insert(
                id: row['id'] as String,
                userId: userId,
                prescriptionId: row['prescription_id'] as String,
                prescriptionVersionId: row['prescription_version_id'] as String,
                prescriptionItemId: row['prescription_item_id'] as String,
                routineId: row['routine_id'] as String,
                planId: row['plan_id'] as String,
                active: Value(row['active'] as bool? ?? true),
                createdAt: _date(row['created_at'])!,
                updatedAt: _date(row['updated_at'])!,
                deletedAt: Value(_date(row['deleted_at'])),
                syncStatus: status,
              ),
            );
        return;
    }
  }

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) =>
      _mark(recordId, 'synced');

  @override
  Future<void> markFailed(String recordId, SyncError error) =>
      _mark(recordId, 'failed');

  Future<void> _mark(String recordId, String status) async {
    final parts = recordId.split('|');
    if (parts.length != 2 || !_tables.contains(parts.first)) return;
    await database.customUpdate(
      'UPDATE ${_localTable(parts.first)} SET sync_status = ? WHERE user_id = ? AND id = ?',
      variables: [
        Variable<String>(status),
        Variable<String>(userId),
        Variable<String>(parts.last),
      ],
      updates: const {},
    );
  }

  SyncOperation _operation(String table, Map<String, Object?> local) {
    final row = _remoteRow(local);
    final id = row['id'] as String;
    final deletedAt = _date(row['deleted_at']);
    return SyncOperation(
      repositoryKey: key,
      recordId: '$table|$id',
      type: deletedAt == null
          ? SyncOperationType.update
          : SyncOperationType.delete,
      updatedAt: _date(row['updated_at'])!,
      deletedAt: deletedAt,
      userId: userId,
      payload: {'table': table, 'row': row},
    );
  }

  Map<String, Object?> _remoteRow(Map<String, Object?> values) => {
    for (final entry in values.entries)
      if (entry.key != 'sync_status')
        _remoteKey(entry.key): _remoteFieldValue(entry.key, entry.value),
  };

  Object? _remoteFieldValue(String key, Object? value) {
    if ({'snapshot_json', 'field_decisions_json', 'draft_json'}.contains(key) &&
        value is String) {
      return jsonDecode(value);
    }
    return _remoteValue(value);
  }

  String _remoteKey(String value) => switch (value) {
    'snapshot_json' => 'snapshot',
    'field_decisions_json' => 'field_decisions',
    'draft_json' => 'draft',
    _ => _snake(value),
  };

  Object? _remoteValue(Object? value) => switch (value) {
    DateTime date => date.toUtc().toIso8601String(),
    _ => value,
  };

  String _localTable(String remoteTable) => switch (remoteTable) {
    'prescription_versions' => 'prescription_version_records',
    'prescription_reviews' => 'prescription_review_records',
    'treatment_proposals' => 'treatment_proposal_records',
    'prescription_routine_links' => 'prescription_routine_link_records',
    _ => throw StateError('Unknown prescription platform table.'),
  };

  String _snake(String value) => value.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );

  DateTime? _date(Object? value) => value == null
      ? null
      : value is DateTime
      ? value.toUtc()
      : DateTime.parse(value as String).toUtc();

  String _json(Object? value) => value is String
      ? value
      : const JsonEncoder().convert(value ?? const <String, Object?>{});
}

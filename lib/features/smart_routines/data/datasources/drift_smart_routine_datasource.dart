import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/smart_routine_dao.dart';
import '../dtos/smart_routine_dtos.dart';

final class DriftSmartRoutineDatasource {
  const DriftSmartRoutineDatasource({required this.dao, required this.userId});
  final SmartRoutineDao dao;
  final String userId;

  Future<void> saveRoutine(SmartRoutineDto dto) =>
      dao.upsertRoutine(_routine(dto));
  Future<void> savePlan(RoutinePlanDto dto) => dao.upsertPlan(_plan(dto));
  Future<void> saveSchedule(RoutineScheduleDto dto) =>
      dao.upsertSchedule(_schedule(dto));
  Future<void> savePause(RoutinePauseDto dto) => dao.upsertPause(_pause(dto));
  Future<bool> materializeOccurrence(RoutineOccurrenceDto dto) =>
      dao.insertOccurrenceIdempotent(_occurrence(dto));
  Future<bool> appendEvent(RoutineAdherenceEventDto dto) =>
      dao.insertEventIdempotent(_event(dto));

  Future<List<SmartRoutineLocalRecord>> pendingSync() async {
    final records = <SmartRoutineLocalRecord>[];
    Future<void> add(String type, Future<List<dynamic>> query) async {
      for (final record in await query) {
        records.add(
          SmartRoutineLocalRecord(
            type,
            _remoteMap(record.toJson() as Map<String, dynamic>),
          ),
        );
      }
    }

    await add('smart_routines', dao.getPendingRoutines(userId));
    await add('routine_plans', dao.getPendingPlans(userId));
    await add('routine_schedules', dao.getPendingSchedules(userId));
    await add('routine_pauses', dao.getPendingPauses(userId));
    await add('routine_occurrences', dao.getPendingOccurrences(userId));
    await add('routine_adherence_events', dao.getPendingEvents(userId));
    return records;
  }

  Future<void> markSync(
    String table,
    String id,
    String status, {
    String? error,
  }) => dao.updateSyncStatus(
    table: _localTable(table),
    userId: userId,
    id: id,
    status: status,
    error: error,
  );

  Future<void> materializeAndAppend({
    required RoutineOccurrenceDto occurrence,
    required RoutineAdherenceEventDto event,
  }) => dao.inTransaction(() async {
    await materializeOccurrence(occurrence);
    await appendEvent(event);
  });

  Future<void> rescheduleAndAppend({
    required RoutineOccurrenceDto occurrence,
    required RoutineAdherenceEventDto event,
  }) => dao.inTransaction(() async {
    final existing = await dao.getOccurrence(userId, occurrence.entity.id);
    if (existing == null) throw StateError('routine_occurrence_parent_missing');
    await dao.updateOccurrenceCurrentWindow(_occurrence(occurrence));
    await appendEvent(event);
  });

  SmartRoutineRecordsCompanion _routine(SmartRoutineDto dto) {
    final row = dto.toRow();
    _owned(row);
    return SmartRoutineRecordsCompanion.insert(
      id: row['id'] as String,
      userId: userId,
      category: row['category'] as String,
      displayName: row['display_name'] as String,
      status: row['status'] as String,
      source: row['source'] as String,
      prescriptionId: Value(row['prescription_id'] as String?),
      prescriptionItemId: Value(row['prescription_item_id'] as String?),
      personalNotes: Value(row['personal_notes'] as String?),
      iconKey: Value(row['icon_key'] as String?),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      deletedAt: Value(_nullableDate(row['deleted_at'])),
      syncStatus: row['sync_status'] as String,
    );
  }

  RoutinePlanRecordsCompanion _plan(RoutinePlanDto dto) {
    final r = dto.toRow();
    _owned(r);
    return RoutinePlanRecordsCompanion.insert(
      id: r['id'] as String,
      userId: userId,
      routineId: r['routine_id'] as String,
      revision: r['revision'] as int,
      mode: r['mode'] as String,
      durationType: r['duration_type'] as String,
      effectiveFrom: r['effective_from'] as String,
      effectiveUntil: Value(r['effective_until'] as String?),
      doseValue: Value(r['dose_value'] as String?),
      doseUnit: Value(r['dose_unit'] as String?),
      doseOriginalText: Value(r['dose_original_text'] as String?),
      route: Value(r['route'] as String?),
      clinicalInstructions: Value(r['clinical_instructions'] as String?),
      activatedAt: Value(_nullableDate(r['activated_at'])),
      replacedAt: Value(_nullableDate(r['replaced_at'])),
      previousPlanId: Value(r['previous_plan_id'] as String?),
      createdAt: _date(r['created_at']),
      updatedAt: _date(r['updated_at']),
      deletedAt: Value(_nullableDate(r['deleted_at'])),
      syncStatus: r['sync_status'] as String,
    );
  }

  RoutineScheduleRecordsCompanion _schedule(RoutineScheduleDto dto) {
    final r = dto.toRow();
    _owned(r);
    return RoutineScheduleRecordsCompanion.insert(
      id: r['id'] as String,
      userId: userId,
      routineId: r['routine_id'] as String,
      planId: r['plan_id'] as String,
      ruleJson: jsonEncode(r['rule']),
      timeZone: r['time_zone'] as String,
      reminderPreference: r['reminder_preference'] as String,
      earlyToleranceSeconds: r['early_tolerance_seconds'] as int,
      onTimeToleranceSeconds: r['on_time_tolerance_seconds'] as int,
      lateToleranceSeconds: r['late_tolerance_seconds'] as int,
      isEnabled: r['is_enabled'] as bool,
      displayOrder: r['display_order'] as int,
      createdAt: _date(r['created_at']),
      updatedAt: _date(r['updated_at']),
      deletedAt: Value(_nullableDate(r['deleted_at'])),
      syncStatus: r['sync_status'] as String,
    );
  }

  RoutinePauseRecordsCompanion _pause(RoutinePauseDto dto) {
    final r = dto.toRow();
    _owned(r);
    return RoutinePauseRecordsCompanion.insert(
      id: r['id'] as String,
      userId: userId,
      routineId: r['routine_id'] as String,
      planId: Value(r['plan_id'] as String?),
      scope: r['scope'] as String,
      startsAt: _date(r['starts_at']),
      endsAt: Value(_nullableDate(r['ends_at'])),
      reason: Value(r['reason'] as String?),
      createdAt: _date(r['created_at']),
      updatedAt: _date(r['updated_at']),
      deletedAt: Value(_nullableDate(r['deleted_at'])),
      syncStatus: r['sync_status'] as String,
    );
  }

  RoutineOccurrenceRecordsCompanion _occurrence(RoutineOccurrenceDto dto) {
    final r = dto.toRow();
    _owned(r);
    return RoutineOccurrenceRecordsCompanion.insert(
      id: r['id'] as String,
      userId: userId,
      routineId: r['routine_id'] as String,
      planId: r['plan_id'] as String,
      scheduleId: Value(r['schedule_id'] as String?),
      origin: r['origin'] as String,
      status: r['status'] as String,
      originalClinicalDate: r['original_clinical_date'] as String,
      originalLocalHour: r['original_local_hour'] as int,
      originalLocalMinute: r['original_local_minute'] as int,
      originalTimeZone: r['original_time_zone'] as String,
      expectationKind: r['expectation_kind'] as String,
      sequence: r['sequence'] as int,
      originalScheduledFor: _date(r['original_scheduled_for']),
      originalWindowStartsAt: _date(r['original_window_starts_at']),
      originalOnTimeEndsAt: _date(r['original_on_time_ends_at']),
      originalWindowEndsAt: _date(r['original_window_ends_at']),
      scheduledFor: _date(r['scheduled_for']),
      windowStartsAt: _date(r['window_starts_at']),
      onTimeEndsAt: _date(r['on_time_ends_at']),
      windowEndsAt: _date(r['window_ends_at']),
      createdAt: _date(r['created_at']),
      updatedAt: _date(r['updated_at']),
      deletedAt: Value(_nullableDate(r['deleted_at'])),
      syncStatus: r['sync_status'] as String,
    );
  }

  RoutineAdherenceEventRecordsCompanion _event(RoutineAdherenceEventDto dto) {
    final r = dto.toRow();
    _owned(r);
    return RoutineAdherenceEventRecordsCompanion.insert(
      id: r['id'] as String,
      userId: userId,
      occurrenceId: r['occurrence_id'] as String,
      routineId: r['routine_id'] as String,
      planId: r['plan_id'] as String,
      scheduleId: Value(r['schedule_id'] as String?),
      type: r['type'] as String,
      actor: r['actor'] as String,
      occurredAtUtc: _date(r['occurred_at_utc']),
      recordedAtUtc: _date(r['recorded_at_utc']),
      referencedEventId: Value(r['referenced_event_id'] as String?),
      correctionAction: Value(r['correction_action'] as String?),
      replacementType: Value(r['replacement_type'] as String?),
      replacementOccurredAtUtc: Value(
        _nullableDate(r['replacement_occurred_at_utc']),
      ),
      rescheduledForUtc: Value(_nullableDate(r['rescheduled_for_utc'])),
      rescheduledWindowStartsAtUtc: Value(
        _nullableDate(r['rescheduled_window_starts_at_utc']),
      ),
      rescheduledOnTimeEndsAtUtc: Value(
        _nullableDate(r['rescheduled_on_time_ends_at_utc']),
      ),
      rescheduledWindowEndsAtUtc: Value(
        _nullableDate(r['rescheduled_window_ends_at_utc']),
      ),
      note: Value(r['note'] as String?),
      actualDoseValue: Value(r['actual_dose_value'] as String?),
      actualDoseUnit: Value(r['actual_dose_unit'] as String?),
      actualDoseOriginalText: Value(r['actual_dose_original_text'] as String?),
      createdAt: _date(r['created_at']),
      updatedAt: _date(r['updated_at']),
      deletedAt: Value(_nullableDate(r['deleted_at'])),
      syncStatus: r['sync_status'] as String,
    );
  }

  void _owned(Map<String, dynamic> row) {
    if (row['user_id'] != userId) {
      throw StateError('smart_routine_user_mismatch');
    }
  }

  DateTime _date(Object? value) =>
      value is DateTime ? value : DateTime.parse(value as String);
  DateTime? _nullableDate(Object? value) => value == null ? null : _date(value);

  Map<String, dynamic> _remoteMap(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      result[key == 'rule_json' ? 'rule' : key] = key == 'rule_json'
          ? jsonDecode(entry.value as String)
          : entry.value;
    }
    return result;
  }

  String _localTable(String remote) => switch (remote) {
    'smart_routines' => 'smart_routine_records',
    'routine_plans' => 'routine_plan_records',
    'routine_schedules' => 'routine_schedule_records',
    'routine_pauses' => 'routine_pause_records',
    'routine_occurrences' => 'routine_occurrence_records',
    'routine_adherence_events' => 'routine_adherence_event_records',
    _ => throw ArgumentError.value(remote, 'remote'),
  };
}

final class SmartRoutineLocalRecord {
  const SmartRoutineLocalRecord(this.table, this.row);
  final String table;
  final Map<String, dynamic> row;
}

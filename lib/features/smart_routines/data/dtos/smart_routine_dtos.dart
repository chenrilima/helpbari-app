import 'dart:convert';

import '../../../../core/sync/sync.dart';
import '../../domain/smart_routines_domain.dart';

final class ScheduleRuleCodec {
  const ScheduleRuleCodec();
  static const schemaVersion = 1;

  String encode(ScheduleRule rule) => jsonEncode(toJson(rule));

  Map<String, dynamic> toJson(ScheduleRule rule) => switch (rule) {
    DailyAtTimesRule(:final times) => _base('dailyAtTimes', {
      'times': _times(times),
    }),
    SpecificWeekdaysAtTimesRule(:final weekdays, :final times) => _base(
      'specificWeekdaysAtTimes',
      {
        'weekdays': weekdays.values.toList(growable: false),
        'times': _times(times),
      },
    ),
    EveryNHoursRule(:final intervalHours, :final anchorAtUtc) => _base(
      'everyNHours',
      {'intervalHours': intervalHours, 'anchorAtUtc': _utc(anchorAtUtc)},
    ),
    EveryNDaysRule(:final intervalDays, :final anchorDate, :final times) =>
      _base('everyNDays', {
        'intervalDays': intervalDays,
        'anchorDate': anchorDate.toString(),
        'times': _times(times),
      }),
    WeeklyRule(:final weekday, :final times) => _base('weekly', {
      'weekday': weekday,
      'times': _times(times),
    }),
    MonthlyRule(:final dayOfMonth, :final times) => _base('monthly', {
      'dayOfMonth': dayOfMonth,
      'times': _times(times),
    }),
    SingleDoseRule(:final scheduledAt) => _base('singleDose', {
      'scheduledAt': scheduledAt.toIso8601String(),
      'isUtc': scheduledAt.isUtc,
    }),
    FreeFormRule(:final instructions) => _base('freeForm', {
      'instructions': instructions,
    }),
    AsNeededRule() => _base('asNeeded'),
  };

  ScheduleRule decode(String value) =>
      fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));

  ScheduleRule fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported schedule rule schema.');
    }
    final type = _string(json, 'type');
    return switch (type) {
      'dailyAtTimes' => DailyAtTimesRule(_readTimes(json)),
      'specificWeekdaysAtTimes' => SpecificWeekdaysAtTimesRule(
        weekdays: WeekdaySet(_ints(json, 'weekdays')),
        times: _readTimes(json),
      ),
      'everyNHours' => EveryNHoursRule(
        _integer(json, 'intervalHours'),
        anchorAtUtc: _utcDate(json, 'anchorAtUtc'),
      ),
      'everyNDays' => EveryNDaysRule(
        intervalDays: _integer(json, 'intervalDays'),
        anchorDate: _localDate(_string(json, 'anchorDate')),
        times: _readTimes(json),
      ),
      'weekly' => WeeklyRule(
        weekday: _integer(json, 'weekday'),
        times: _readTimes(json),
      ),
      'monthly' => MonthlyRule(
        dayOfMonth: _integer(json, 'dayOfMonth'),
        times: _readTimes(json),
      ),
      'singleDose' => SingleDoseRule(
        DateTime.parse(_string(json, 'scheduledAt')),
      ),
      'freeForm' => FreeFormRule(_string(json, 'instructions')),
      'asNeeded' => const AsNeededRule(),
      _ => throw FormatException('Unknown schedule rule type: $type'),
    };
  }

  Map<String, dynamic> _base(String type, [Map<String, dynamic>? values]) => {
    'schemaVersion': schemaVersion,
    'type': type,
    ...?values,
  };
  List<String> _times(Iterable<TimeOfDayValue> values) =>
      values.map((value) => value.toString()).toList(growable: false);
  List<TimeOfDayValue> _readTimes(Map<String, dynamic> json) =>
      _list(json, 'times')
          .map((value) => TimeOfDayValue.parse(value as String))
          .toList(growable: false);
  List<int> _ints(Map<String, dynamic> json, String key) =>
      _list(json, key).map((value) => value as int).toList(growable: false);
  List<dynamic> _list(Map<String, dynamic> json, String key) =>
      (json[key] as List?)?.toList(growable: false) ??
      (throw FormatException('$key is required.'));
  String _string(Map<String, dynamic> json, String key) =>
      json[key] is String && (json[key] as String).isNotEmpty
      ? json[key] as String
      : throw FormatException('$key is required.');
  int _integer(Map<String, dynamic> json, String key) => json[key] is int
      ? json[key] as int
      : throw FormatException('$key is required.');
  DateTime _utcDate(Map<String, dynamic> json, String key) {
    final value = DateTime.parse(_string(json, key));
    if (!value.isUtc) throw FormatException('$key must be UTC.');
    return value;
  }
}

final class SmartRoutineDto {
  const SmartRoutineDto(this.entity, this.metadata);
  final SmartRoutine entity;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'category': entity.category.name,
    'display_name': entity.displayName,
    'status': entity.status.name,
    'source': entity.source.name,
    'prescription_id': entity.prescriptionReference?.prescriptionId.value,
    'prescription_item_id':
        entity.prescriptionReference?.prescriptionItemId.value,
    'personal_notes': entity.personalNotes,
    'icon_key': entity.iconKey,
  };
  factory SmartRoutineDto.fromRow(Map<String, dynamic> row) {
    final metadata = _metadata(row);
    return SmartRoutineDto(
      SmartRoutine(
        routineId: RoutineId(row['id'] as String),
        category: _enum(RoutineCategory.values, row['category'], 'category'),
        displayName: row['display_name'] as String,
        status: _enum(RoutineStatus.values, row['status'], 'status'),
        source: _enum(RoutineSource.values, row['source'], 'source'),
        createdAt: metadata.createdAt,
        updatedAt: metadata.updatedAt,
        prescriptionReference: row['prescription_id'] == null
            ? null
            : PrescriptionItemReference(
                prescriptionId: PrescriptionId(
                  row['prescription_id'] as String,
                ),
                prescriptionItemId: PrescriptionItemId(
                  row['prescription_item_id'] as String,
                ),
              ),
        personalNotes: row['personal_notes'] as String?,
        iconKey: row['icon_key'] as String?,
        deletedAt: metadata.deletedAt,
      ),
      metadata,
    );
  }
}

final class RoutinePlanDto {
  const RoutinePlanDto(this.entity, this.metadata);
  final RoutinePlan entity;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'routine_id': entity.routineId.value,
    'revision': entity.revision,
    'mode': entity.mode.name,
    'duration_type': entity.durationType.name,
    'effective_from': entity.effectiveFrom.toString(),
    'effective_until': entity.effectiveUntil?.toString(),
    'dose_value': entity.dose?.value,
    'dose_unit': entity.dose?.unit,
    'dose_original_text': entity.dose?.originalText,
    'route': entity.route,
    'clinical_instructions': entity.clinicalInstructions,
    'activated_at': _utcOrNull(entity.activatedAt),
    'replaced_at': _utcOrNull(entity.replacedAt),
    'previous_plan_id': entity.previousPlanId?.value,
  };
  factory RoutinePlanDto.fromRow(Map<String, dynamic> row) {
    final metadata = _metadata(row);
    final dose = row['dose_value'] == null && row['dose_original_text'] == null
        ? null
        : DoseValue(
            value: row['dose_value'] as String?,
            unit: row['dose_unit'] as String?,
            originalText: row['dose_original_text'] as String?,
          );
    return RoutinePlanDto(
      RoutinePlan(
        planId: RoutinePlanId(row['id'] as String),
        routineId: RoutineId(row['routine_id'] as String),
        revision: row['revision'] as int,
        mode: _enum(RoutinePlanMode.values, row['mode'], 'mode'),
        durationType: _enum(
          PlanDurationType.values,
          row['duration_type'],
          'duration_type',
        ),
        effectiveFrom: _localDate(row['effective_from'] as String),
        effectiveUntil: row['effective_until'] == null
            ? null
            : _localDate(row['effective_until'] as String),
        dose: dose,
        route: row['route'] as String?,
        clinicalInstructions: row['clinical_instructions'] as String?,
        createdAt: metadata.createdAt,
        activatedAt: _dateOrNull(row['activated_at']),
        replacedAt: _dateOrNull(row['replaced_at']),
        previousPlanId: row['previous_plan_id'] == null
            ? null
            : RoutinePlanId(row['previous_plan_id'] as String),
      ),
      metadata,
    );
  }
}

final class RoutineScheduleDto {
  const RoutineScheduleDto(this.entity, this.routineId, this.metadata);
  final RoutineSchedule entity;
  final RoutineId routineId;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'routine_id': routineId.value,
    'plan_id': entity.planId.value,
    'rule': const ScheduleRuleCodec().toJson(entity.rule),
    'time_zone': entity.timeZone.value,
    'reminder_preference': entity.reminderPreference.name,
    'early_tolerance_seconds': entity.earlyTolerance.inSeconds,
    'on_time_tolerance_seconds': entity.onTimeTolerance.inSeconds,
    'late_tolerance_seconds': entity.lateTolerance.inSeconds,
    'is_enabled': entity.isEnabled,
    'display_order': entity.displayOrder,
  };
  factory RoutineScheduleDto.fromRow(
    Map<String, dynamic> row,
    RoutinePlan plan,
  ) => RoutineScheduleDto(
    RoutineSchedule(
      scheduleId: RoutineScheduleId(row['id'] as String),
      plan: plan,
      rule: const ScheduleRuleCodec().fromJson(
        Map<String, dynamic>.from(row['rule'] as Map),
      ),
      timeZone: IanaTimeZone(row['time_zone'] as String),
      reminderPreference: _enum(
        RoutineReminderPreference.values,
        row['reminder_preference'],
        'reminder_preference',
      ),
      earlyTolerance: Duration(seconds: row['early_tolerance_seconds'] as int),
      onTimeTolerance: Duration(
        seconds: row['on_time_tolerance_seconds'] as int,
      ),
      lateTolerance: Duration(seconds: row['late_tolerance_seconds'] as int),
      isEnabled: row['is_enabled'] as bool,
      displayOrder: row['display_order'] as int,
    ),
    RoutineId(row['routine_id'] as String),
    _metadata(row),
  );
}

final class RoutinePauseDto {
  const RoutinePauseDto(this.entity, this.metadata);
  final RoutinePause entity;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'routine_id': entity.routineId.value,
    'plan_id': entity.planId?.value,
    'scope': entity.scope.name,
    'starts_at': _utc(entity.startsAt),
    'ends_at': _utcOrNull(entity.endsAt),
    'reason': entity.reason,
  };
  factory RoutinePauseDto.fromRow(Map<String, dynamic> row) => RoutinePauseDto(
    RoutinePause(
      pauseId: RoutinePauseId(row['id'] as String),
      routineId: RoutineId(row['routine_id'] as String),
      scope: _enum(RoutinePauseScope.values, row['scope'], 'scope'),
      startsAt: _utcDateValue(row['starts_at']),
      endsAt: _dateOrNull(row['ends_at']),
      createdAt: _metadata(row).createdAt,
      planId: row['plan_id'] == null
          ? null
          : RoutinePlanId(row['plan_id'] as String),
      reason: row['reason'] as String?,
    ),
    _metadata(row),
  );
}

final class RoutineOccurrenceDto {
  const RoutineOccurrenceDto(this.entity, this.metadata);
  final RoutineOccurrence entity;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'routine_id': entity.routineId.value,
    'plan_id': entity.planId.value,
    'schedule_id': entity.scheduleId?.value,
    'origin': entity.origin.name,
    'status': entity.status.name,
    'original_clinical_date': entity.originalClinicalDate.toString(),
    'original_local_hour': entity.originalLocalTime.hour,
    'original_local_minute': entity.originalLocalTime.minute,
    'original_time_zone': entity.originalTimeZone.value,
    'expectation_kind': entity.expectationKind.name,
    'sequence': entity.sequence,
    'original_scheduled_for': _utc(entity.originalScheduledFor),
    'original_window_starts_at': _utc(entity.originalWindow.windowStartsAt),
    'original_on_time_ends_at': _utc(entity.originalWindow.onTimeEndsAt),
    'original_window_ends_at': _utc(entity.originalWindow.windowEndsAt),
    'scheduled_for': _utc(entity.currentScheduledFor),
    'window_starts_at': _utc(entity.currentWindow.windowStartsAt),
    'on_time_ends_at': _utc(entity.currentWindow.onTimeEndsAt),
    'window_ends_at': _utc(entity.currentWindow.windowEndsAt),
  };
  factory RoutineOccurrenceDto.fromRow(Map<String, dynamic> row) {
    final originalTarget = _utcDateValue(row['original_scheduled_for']);
    final currentTarget = _utcDateValue(row['scheduled_for']);
    final originalWindow = OccurrenceWindow(
      windowStartsAt: _utcDateValue(row['original_window_starts_at']),
      scheduledFor: originalTarget,
      onTimeEndsAt: _utcDateValue(row['original_on_time_ends_at']),
      windowEndsAt: _utcDateValue(row['original_window_ends_at']),
    );
    final currentWindow = OccurrenceWindow(
      windowStartsAt: _utcDateValue(row['window_starts_at']),
      scheduledFor: currentTarget,
      onTimeEndsAt: _utcDateValue(row['on_time_ends_at']),
      windowEndsAt: _utcDateValue(row['window_ends_at']),
    );
    return RoutineOccurrenceDto(
      RoutineOccurrence(
        occurrenceId: RoutineOccurrenceId(row['id'] as String),
        routineId: RoutineId(row['routine_id'] as String),
        planId: RoutinePlanId(row['plan_id'] as String),
        scheduleId: row['schedule_id'] == null
            ? null
            : RoutineScheduleId(row['schedule_id'] as String),
        origin: _enum(RoutineOccurrenceOrigin.values, row['origin'], 'origin'),
        originalWindow: originalWindow,
        currentWindow: currentWindow,
        status: _enum(RoutineOccurrenceStatus.values, row['status'], 'status'),
        originalClinicalDate: _localDate(
          row['original_clinical_date'] as String,
        ),
        originalLocalTime: TimeOfDayValue(
          hour: row['original_local_hour'] as int,
          minute: row['original_local_minute'] as int,
        ),
        originalTimeZone: IanaTimeZone(row['original_time_zone'] as String),
        expectationKind: _enum(
          ExpectationKind.values,
          row['expectation_kind'],
          'expectation_kind',
        ),
        sequence: row['sequence'] as int,
      ),
      _metadata(row),
    );
  }
}

final class RoutineAdherenceEventDto {
  const RoutineAdherenceEventDto(this.entity, this.metadata);
  final RoutineAdherenceEvent entity;
  final SyncMetadata metadata;
  Map<String, dynamic> toRow() => {
    ..._metadataRow(metadata),
    'occurrence_id': entity.occurrenceId.value,
    'routine_id': entity.routineId.value,
    'plan_id': entity.planId.value,
    'schedule_id': entity.scheduleId?.value,
    'type': entity.type.name,
    'actor': entity.actor.name,
    'occurred_at_utc': _utc(entity.occurredAtUtc),
    'recorded_at_utc': _utc(entity.recordedAtUtc),
    'referenced_event_id': entity.referencedEventId?.value,
    'correction_action': entity.correctionAction?.name,
    'replacement_type': entity.replacementType?.name,
    'replacement_occurred_at_utc': _utcOrNull(entity.replacementOccurredAtUtc),
    'rescheduled_for_utc': _utcOrNull(entity.rescheduledWindow?.scheduledFor),
    'rescheduled_window_starts_at_utc': _utcOrNull(
      entity.rescheduledWindow?.windowStartsAt,
    ),
    'rescheduled_on_time_ends_at_utc': _utcOrNull(
      entity.rescheduledWindow?.onTimeEndsAt,
    ),
    'rescheduled_window_ends_at_utc': _utcOrNull(
      entity.rescheduledWindow?.windowEndsAt,
    ),
    'note': entity.note,
    'actual_dose_value': entity.actualDose?.value,
    'actual_dose_unit': entity.actualDose?.unit,
    'actual_dose_original_text': entity.actualDose?.originalText,
  };
  factory RoutineAdherenceEventDto.fromRow(Map<String, dynamic> row) {
    final rescheduled = row['rescheduled_for_utc'] == null
        ? null
        : OccurrenceWindow(
            windowStartsAt: _utcDateValue(
              row['rescheduled_window_starts_at_utc'],
            ),
            scheduledFor: _utcDateValue(row['rescheduled_for_utc']),
            onTimeEndsAt: _utcDateValue(row['rescheduled_on_time_ends_at_utc']),
            windowEndsAt: _utcDateValue(row['rescheduled_window_ends_at_utc']),
          );
    final actualDose =
        row['actual_dose_value'] == null &&
            row['actual_dose_original_text'] == null
        ? null
        : DoseValue(
            value: row['actual_dose_value'] as String?,
            unit: row['actual_dose_unit'] as String?,
            originalText: row['actual_dose_original_text'] as String?,
          );
    return RoutineAdherenceEventDto(
      RoutineAdherenceEvent(
        eventId: RoutineAdherenceEventId(row['id'] as String),
        occurrenceId: RoutineOccurrenceId(row['occurrence_id'] as String),
        routineId: RoutineId(row['routine_id'] as String),
        planId: RoutinePlanId(row['plan_id'] as String),
        scheduleId: row['schedule_id'] == null
            ? null
            : RoutineScheduleId(row['schedule_id'] as String),
        type: _enum(AdherenceEventType.values, row['type'], 'type'),
        actor: _enum(AdherenceEventActor.values, row['actor'], 'actor'),
        occurredAtUtc: _utcDateValue(row['occurred_at_utc']),
        recordedAtUtc: _utcDateValue(row['recorded_at_utc']),
        referencedEventId: row['referenced_event_id'] == null
            ? null
            : RoutineAdherenceEventId(row['referenced_event_id'] as String),
        correctionAction: row['correction_action'] == null
            ? null
            : _enum(
                AdherenceCorrectionAction.values,
                row['correction_action'],
                'correction_action',
              ),
        replacementType: row['replacement_type'] == null
            ? null
            : _enum(
                AdherenceEventType.values,
                row['replacement_type'],
                'replacement_type',
              ),
        replacementOccurredAtUtc: _dateOrNull(
          row['replacement_occurred_at_utc'],
        ),
        rescheduledWindow: rescheduled,
        note: row['note'] as String?,
        actualDose: actualDose,
      ),
      _metadata(row),
    );
  }
}

Map<String, dynamic> _metadataRow(SyncMetadata value) => {
  'id': value.id,
  'user_id': value.userId,
  'created_at': _utc(value.createdAt),
  'updated_at': _utc(value.updatedAt),
  'deleted_at': _utcOrNull(value.deletedAt),
  'sync_status': value.syncStatus.name,
};
SyncMetadata _metadata(Map<String, dynamic> row) => SyncMetadata(
  id: row['id'] as String,
  userId: row['user_id'] as String,
  createdAt: _utcDateValue(row['created_at']),
  updatedAt: _utcDateValue(row['updated_at']),
  deletedAt: _dateOrNull(row['deleted_at']),
  syncStatus: SyncStatus.fromName(row['sync_status'] as String?),
);
T _enum<T extends Enum>(List<T> values, Object? raw, String field) =>
    values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown $field: $raw'),
    );
LocalDate _localDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Invalid LocalDate: $value');
  return LocalDate(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
  );
}

DateTime _utcDateValue(Object? value) {
  final date = value is DateTime ? value : DateTime.parse(value as String);
  if (!date.isUtc) throw const FormatException('UTC timestamp required.');
  return date;
}

DateTime? _dateOrNull(Object? value) =>
    value == null ? null : _utcDateValue(value);
String _utc(DateTime value) {
  if (!value.isUtc) throw const FormatException('UTC timestamp required.');
  return value.toIso8601String();
}

String? _utcOrNull(DateTime? value) => value == null ? null : _utc(value);

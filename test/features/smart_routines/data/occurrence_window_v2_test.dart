import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/smart_routines/data/repositories/drift_occurrence_window_service.dart';
import 'package:helpbari/features/smart_routines/domain/enums/routine_enums.dart';
import 'package:helpbari/features/smart_routines/domain/services/routine_occurrence_identity_generator.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/local_date.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/occurrence_blueprint.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/routine_values.dart';
import 'package:helpbari/features/smart_routines/domain/value_objects/typed_ids.dart';

void main() {
  setUpAll(IanaTimezoneBootstrap.initialize);

  test('window uses canonical identity, shifts DST gap and is idempotent', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 3, 1);
    await database.customInsert(
      "INSERT INTO smart_routine_records "
      "(id,user_id,category,display_name,status,source,created_at,updated_at,sync_status,sync_attempts) "
      "VALUES ('$_routineId','user-a','medication','Routine','active','manual',?,?, 'synced',0)",
      variables: [Variable<DateTime>(createdAt), Variable<DateTime>(createdAt)],
    );
    await database.customInsert(
      "INSERT INTO routine_plan_records "
      "(id,user_id,routine_id,revision,category,mode,duration_type,effective_from,activated_at,provenance_origin,validation_status,temporal_precision,created_at,updated_at,sync_status,sync_attempts) "
      "VALUES ('$_planId','user-a','$_routineId',1,'medication','scheduled','continuous','2026-03-01',?,'manual','confirmed','exact',?,?, 'synced',0)",
      variables: [
        Variable<DateTime>(createdAt),
        Variable<DateTime>(createdAt),
        Variable<DateTime>(createdAt),
      ],
    );
    await database.customInsert(
      "INSERT INTO routine_schedule_records "
      "(id,user_id,routine_id,plan_id,rule_json,time_zone,reminder_preference,early_tolerance_seconds,on_time_tolerance_seconds,late_tolerance_seconds,is_enabled,display_order,created_at,updated_at,sync_status,sync_attempts) "
      "VALUES ('$_scheduleId','user-a','$_routineId','$_planId','{\"schemaVersion\":1,\"type\":\"dailyAtTimes\",\"times\":[\"02:30\"]}','America/New_York','enabled',0,1800,43200,1,0,?,?, 'synced',0)",
      variables: [Variable<DateTime>(createdAt), Variable<DateTime>(createdAt)],
    );
    final service = DriftOccurrenceWindowService(
      database: database,
      userId: 'user-a',
      clock: _Clock(createdAt),
    );

    final first = await service.materializeAndProject(
      fromUtc: DateTime.utc(2026, 3, 8, 0),
      untilUtc: DateTime.utc(2026, 3, 9, 0),
    );
    final second = await service.materializeAndProject(
      fromUtc: DateTime.utc(2026, 3, 8, 0),
      untilUtc: DateTime.utc(2026, 3, 9, 0),
    );

    final blueprint = OccurrenceBlueprint(
      routineId: RoutineId(_routineId),
      planId: RoutinePlanId(_planId),
      scheduleId: RoutineScheduleId(_scheduleId),
      clinicalDate: LocalDate(year: 2026, month: 3, day: 8),
      localTime: TimeOfDayValue(hour: 2, minute: 30),
      timeZone: IanaTimeZone('America/New_York'),
      expectationKind: ExpectationKind.recurringExpectation,
      sequence: 0,
      originalLocalDate: LocalDate(year: 2026, month: 3, day: 8),
      originalLocalTime: TimeOfDayValue(hour: 2, minute: 30),
      sourceRuleType: ScheduleFrequencyType.dailyAtTimes,
      scheduleDisplayOrder: 0,
    );
    final expectedId = const RoutineOccurrenceIdentityGenerator()
        .generate(blueprint)
        .value;
    final row = (await database.select(database.routineOccurrenceRecords).get())
        .where((value) => value.originalClinicalDate == '2026-03-08')
        .single;
    expect(first.map((value) => value.occurrenceId), contains(expectedId));
    expect(second.map((value) => value.occurrenceId), contains(expectedId));
    expect(row.originalLocalHour, 2);
    expect(row.originalLocalMinute, 30);
    expect(row.scheduledFor.toUtc(), DateTime.utc(2026, 3, 8, 7));
    expect(row.syncStatus, 'synced');

    await database.customUpdate(
      "UPDATE routine_schedule_records SET reminder_preference='disabled' "
      "WHERE id='$_scheduleId'",
    );
    final disabled = await service.materializeAndProject(
      fromUtc: DateTime.utc(2026, 3, 9),
      untilUtc: DateTime.utc(2026, 3, 10),
    );
    expect(disabled, isEmpty);
    expect(
      (await database.select(database.routineOccurrenceRecords).get()).where(
        (value) => value.originalClinicalDate == '2026-03-09',
      ),
      hasLength(1),
    );
  });
}

const _routineId = '11111111-1111-4111-8111-111111111111';
const _planId = '21111111-1111-4111-8111-111111111111';
const _scheduleId = '31111111-1111-4111-8111-111111111111';

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

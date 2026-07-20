// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_routine_dao.dart';

// ignore_for_file: type=lint
mixin _$SmartRoutineDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmartRoutineRecordsTable get smartRoutineRecords =>
      attachedDatabase.smartRoutineRecords;
  $RoutinePlanRecordsTable get routinePlanRecords =>
      attachedDatabase.routinePlanRecords;
  $RoutineScheduleRecordsTable get routineScheduleRecords =>
      attachedDatabase.routineScheduleRecords;
  $RoutinePauseRecordsTable get routinePauseRecords =>
      attachedDatabase.routinePauseRecords;
  $RoutineOccurrenceRecordsTable get routineOccurrenceRecords =>
      attachedDatabase.routineOccurrenceRecords;
  $RoutineAdherenceEventRecordsTable get routineAdherenceEventRecords =>
      attachedDatabase.routineAdherenceEventRecords;
  SmartRoutineDaoManager get managers => SmartRoutineDaoManager(this);
}

class SmartRoutineDaoManager {
  final _$SmartRoutineDaoMixin _db;
  SmartRoutineDaoManager(this._db);
  $$SmartRoutineRecordsTableTableManager get smartRoutineRecords =>
      $$SmartRoutineRecordsTableTableManager(
        _db.attachedDatabase,
        _db.smartRoutineRecords,
      );
  $$RoutinePlanRecordsTableTableManager get routinePlanRecords =>
      $$RoutinePlanRecordsTableTableManager(
        _db.attachedDatabase,
        _db.routinePlanRecords,
      );
  $$RoutineScheduleRecordsTableTableManager get routineScheduleRecords =>
      $$RoutineScheduleRecordsTableTableManager(
        _db.attachedDatabase,
        _db.routineScheduleRecords,
      );
  $$RoutinePauseRecordsTableTableManager get routinePauseRecords =>
      $$RoutinePauseRecordsTableTableManager(
        _db.attachedDatabase,
        _db.routinePauseRecords,
      );
  $$RoutineOccurrenceRecordsTableTableManager get routineOccurrenceRecords =>
      $$RoutineOccurrenceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.routineOccurrenceRecords,
      );
  $$RoutineAdherenceEventRecordsTableTableManager
  get routineAdherenceEventRecords =>
      $$RoutineAdherenceEventRecordsTableTableManager(
        _db.attachedDatabase,
        _db.routineAdherenceEventRecords,
      );
}

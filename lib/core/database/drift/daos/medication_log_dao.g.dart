// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_log_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicationLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationLogRecordsTable get medicationLogRecords =>
      attachedDatabase.medicationLogRecords;
  MedicationLogDaoManager get managers => MedicationLogDaoManager(this);
}

class MedicationLogDaoManager {
  final _$MedicationLogDaoMixin _db;
  MedicationLogDaoManager(this._db);
  $$MedicationLogRecordsTableTableManager get medicationLogRecords =>
      $$MedicationLogRecordsTableTableManager(
        _db.attachedDatabase,
        _db.medicationLogRecords,
      );
}

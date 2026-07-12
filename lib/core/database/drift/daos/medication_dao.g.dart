// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicationDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicationRecordsTable get medicationRecords =>
      attachedDatabase.medicationRecords;
  MedicationDaoManager get managers => MedicationDaoManager(this);
}

class MedicationDaoManager {
  final _$MedicationDaoMixin _db;
  MedicationDaoManager(this._db);
  $$MedicationRecordsTableTableManager get medicationRecords =>
      $$MedicationRecordsTableTableManager(
        _db.attachedDatabase,
        _db.medicationRecords,
      );
}

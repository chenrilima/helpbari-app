// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_dao.dart';

// ignore_for_file: type=lint
mixin _$AppointmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppointmentRecordsTable get appointmentRecords =>
      attachedDatabase.appointmentRecords;
  AppointmentDaoManager get managers => AppointmentDaoManager(this);
}

class AppointmentDaoManager {
  final _$AppointmentDaoMixin _db;
  AppointmentDaoManager(this._db);
  $$AppointmentRecordsTableTableManager get appointmentRecords =>
      $$AppointmentRecordsTableTableManager(
        _db.attachedDatabase,
        _db.appointmentRecords,
      );
}

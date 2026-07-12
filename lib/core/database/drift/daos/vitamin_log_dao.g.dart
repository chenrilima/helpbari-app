// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitamin_log_dao.dart';

// ignore_for_file: type=lint
mixin _$VitaminLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $VitaminLogRecordsTable get vitaminLogRecords =>
      attachedDatabase.vitaminLogRecords;
  VitaminLogDaoManager get managers => VitaminLogDaoManager(this);
}

class VitaminLogDaoManager {
  final _$VitaminLogDaoMixin _db;
  VitaminLogDaoManager(this._db);
  $$VitaminLogRecordsTableTableManager get vitaminLogRecords =>
      $$VitaminLogRecordsTableTableManager(
        _db.attachedDatabase,
        _db.vitaminLogRecords,
      );
}

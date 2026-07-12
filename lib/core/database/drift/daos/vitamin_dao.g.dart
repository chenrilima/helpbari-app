// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vitamin_dao.dart';

// ignore_for_file: type=lint
mixin _$VitaminDaoMixin on DatabaseAccessor<AppDatabase> {
  $VitaminRecordsTable get vitaminRecords => attachedDatabase.vitaminRecords;
  VitaminDaoManager get managers => VitaminDaoManager(this);
}

class VitaminDaoManager {
  final _$VitaminDaoMixin _db;
  VitaminDaoManager(this._db);
  $$VitaminRecordsTableTableManager get vitaminRecords =>
      $$VitaminRecordsTableTableManager(
        _db.attachedDatabase,
        _db.vitaminRecords,
      );
}

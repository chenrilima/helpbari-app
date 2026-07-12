// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_dao.dart';

// ignore_for_file: type=lint
mixin _$WeightDaoMixin on DatabaseAccessor<AppDatabase> {
  $WeightRecordsTable get weightRecords => attachedDatabase.weightRecords;
  WeightDaoManager get managers => WeightDaoManager(this);
}

class WeightDaoManager {
  final _$WeightDaoMixin _db;
  WeightDaoManager(this._db);
  $$WeightRecordsTableTableManager get weightRecords =>
      $$WeightRecordsTableTableManager(_db.attachedDatabase, _db.weightRecords);
}

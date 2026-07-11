// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_dao.dart';

// ignore_for_file: type=lint
mixin _$WaterDaoMixin on DatabaseAccessor<AppDatabase> {
  $WaterRecordsTable get waterRecords => attachedDatabase.waterRecords;
  WaterDaoManager get managers => WaterDaoManager(this);
}

class WaterDaoManager {
  final _$WaterDaoMixin _db;
  WaterDaoManager(this._db);
  $$WaterRecordsTableTableManager get waterRecords =>
      $$WaterRecordsTableTableManager(_db.attachedDatabase, _db.waterRecords);
}

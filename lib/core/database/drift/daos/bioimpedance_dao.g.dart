// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bioimpedance_dao.dart';

// ignore_for_file: type=lint
mixin _$BioimpedanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $BioimpedanceRecordsTable get bioimpedanceRecords =>
      attachedDatabase.bioimpedanceRecords;
  BioimpedanceDaoManager get managers => BioimpedanceDaoManager(this);
}

class BioimpedanceDaoManager {
  final _$BioimpedanceDaoMixin _db;
  BioimpedanceDaoManager(this._db);
  $$BioimpedanceRecordsTableTableManager get bioimpedanceRecords =>
      $$BioimpedanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.bioimpedanceRecords,
      );
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsRecordsTable get settingsRecords => attachedDatabase.settingsRecords;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsRecordsTableTableManager get settingsRecords =>
      $$SettingsRecordsTableTableManager(
        _db.attachedDatabase,
        _db.settingsRecords,
      );
}

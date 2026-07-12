// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_dao.dart';

// ignore_for_file: type=lint
mixin _$MealDaoMixin on DatabaseAccessor<AppDatabase> {
  $MealRecordsTable get mealRecords => attachedDatabase.mealRecords;
  MealDaoManager get managers => MealDaoManager(this);
}

class MealDaoManager {
  final _$MealDaoMixin _db;
  MealDaoManager(this._db);
  $$MealRecordsTableTableManager get mealRecords =>
      $$MealRecordsTableTableManager(_db.attachedDatabase, _db.mealRecords);
}

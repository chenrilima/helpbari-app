// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_dao.dart';

// ignore_for_file: type=lint
mixin _$ExamDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExamRecordsTable get examRecords => attachedDatabase.examRecords;
  ExamDaoManager get managers => ExamDaoManager(this);
}

class ExamDaoManager {
  final _$ExamDaoMixin _db;
  ExamDaoManager(this._db);
  $$ExamRecordsTableTableManager get examRecords =>
      $$ExamRecordsTableTableManager(_db.attachedDatabase, _db.examRecords);
}

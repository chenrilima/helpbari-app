// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_exam_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicalExamDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicalExamsTable get medicalExams => attachedDatabase.medicalExams;
  $MedicalExamResultsTable get medicalExamResults =>
      attachedDatabase.medicalExamResults;
  MedicalExamDaoManager get managers => MedicalExamDaoManager(this);
}

class MedicalExamDaoManager {
  final _$MedicalExamDaoMixin _db;
  MedicalExamDaoManager(this._db);
  $$MedicalExamsTableTableManager get medicalExams =>
      $$MedicalExamsTableTableManager(_db.attachedDatabase, _db.medicalExams);
  $$MedicalExamResultsTableTableManager get medicalExamResults =>
      $$MedicalExamResultsTableTableManager(
        _db.attachedDatabase,
        _db.medicalExamResults,
      );
}

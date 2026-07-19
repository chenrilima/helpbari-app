// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_prescription_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicalPrescriptionDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicalPrescriptionRecordsTable get medicalPrescriptionRecords =>
      attachedDatabase.medicalPrescriptionRecords;
  $MedicalPrescriptionItemRecordsTable get medicalPrescriptionItemRecords =>
      attachedDatabase.medicalPrescriptionItemRecords;
  MedicalPrescriptionDaoManager get managers =>
      MedicalPrescriptionDaoManager(this);
}

class MedicalPrescriptionDaoManager {
  final _$MedicalPrescriptionDaoMixin _db;
  MedicalPrescriptionDaoManager(this._db);
  $$MedicalPrescriptionRecordsTableTableManager
  get medicalPrescriptionRecords =>
      $$MedicalPrescriptionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.medicalPrescriptionRecords,
      );
  $$MedicalPrescriptionItemRecordsTableTableManager
  get medicalPrescriptionItemRecords =>
      $$MedicalPrescriptionItemRecordsTableTableManager(
        _db.attachedDatabase,
        _db.medicalPrescriptionItemRecords,
      );
}

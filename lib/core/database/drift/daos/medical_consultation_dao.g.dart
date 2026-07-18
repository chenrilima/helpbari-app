// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_consultation_dao.dart';

// ignore_for_file: type=lint
mixin _$MedicalConsultationDaoMixin on DatabaseAccessor<AppDatabase> {
  $MedicalConsultationsTable get medicalConsultations =>
      attachedDatabase.medicalConsultations;
  $MedicalConsultationExamsTable get medicalConsultationExams =>
      attachedDatabase.medicalConsultationExams;
  $MedicalConsultationBodyCompositionsTable
  get medicalConsultationBodyCompositions =>
      attachedDatabase.medicalConsultationBodyCompositions;
  MedicalConsultationDaoManager get managers =>
      MedicalConsultationDaoManager(this);
}

class MedicalConsultationDaoManager {
  final _$MedicalConsultationDaoMixin _db;
  MedicalConsultationDaoManager(this._db);
  $$MedicalConsultationsTableTableManager get medicalConsultations =>
      $$MedicalConsultationsTableTableManager(
        _db.attachedDatabase,
        _db.medicalConsultations,
      );
  $$MedicalConsultationExamsTableTableManager get medicalConsultationExams =>
      $$MedicalConsultationExamsTableTableManager(
        _db.attachedDatabase,
        _db.medicalConsultationExams,
      );
  $$MedicalConsultationBodyCompositionsTableTableManager
  get medicalConsultationBodyCompositions =>
      $$MedicalConsultationBodyCompositionsTableTableManager(
        _db.attachedDatabase,
        _db.medicalConsultationBodyCompositions,
      );
}

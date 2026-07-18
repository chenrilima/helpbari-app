import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart' as db;
import '../../../../core/database/drift/daos/medical_consultation_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../dtos/medical_consultation_dto.dart';

const anonymousMedicalConsultationUserId = 'anonymous';

class DriftMedicalConsultationLocalDatasource {
  const DriftMedicalConsultationLocalDatasource({
    required MedicalConsultationDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final MedicalConsultationDao _dao;
  final ClockService _clock;
  final String userId;

  bool get canSync => userId != anonymousMedicalConsultationUserId;

  Future<List<MedicalConsultation>> getHistory() async {
    final rows = await _dao.getActiveByUser(userId);
    final items = <MedicalConsultation>[];
    for (final row in rows) {
      items.add(await _fromDrift(row));
    }
    return items;
  }

  Future<MedicalConsultation?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null || row.deletedAt != null) return null;
    return _fromDrift(row);
  }

  Future<MedicalConsultation?> getByAppointmentId(String appointmentId) async {
    final row = await _dao.getByUserAndAppointmentId(userId, appointmentId);
    if (row == null) return null;
    return _fromDrift(row);
  }

  Future<void> save(MedicalConsultation consultation) async {
    if (!consultation.hasAnyContent) {
      throw const FormatException(
        'Informe ao menos um conteúdo clínico, documento ou vínculo relevante.',
      );
    }
    final previous = await pendingById(consultation.id);
    final dto = MedicalConsultationDto.fromEntity(
      consultation,
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata,
    );
    await _dao.inTransaction(() async {
      await _dao.upsertConsultation(
        _companion(dto.consultation, dto.syncMetadata),
      );
      await _dao.replaceExamLinks(
        userId,
        consultation.id,
        dto.consultation.relatedExamIds
            .map(
              (examId) => db.MedicalConsultationExamsCompanion.insert(
                userId: userId,
                medicalConsultationId: consultation.id,
                medicalExamId: examId,
              ),
            )
            .toList(growable: false),
      );
      await _dao.replaceBodyCompositionLinks(
        userId,
        consultation.id,
        dto.consultation.relatedBodyCompositionIds
            .map(
              (recordId) =>
                  db.MedicalConsultationBodyCompositionsCompanion.insert(
                    userId: userId,
                    medicalConsultationId: consultation.id,
                    bioimpedanceRecordId: recordId,
                  ),
            )
            .toList(growable: false),
      );
    });
  }

  Future<void> delete(String id) async {
    final previous = await pendingById(id);
    if (previous == null) return;
    final now = _clock.now();
    await _dao.upsertConsultation(
      _companion(
        previous.consultation.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
        previous.syncMetadata.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      ),
    );
  }

  Future<List<MedicalConsultationDto>> pendingSync() async {
    if (!canSync) return const [];
    final rows = await _dao.getPendingForSync(userId);
    final items = <MedicalConsultationDto>[];
    for (final row in rows) {
      final dto = await pendingById(row.id);
      if (dto != null) items.add(dto);
    }
    return items;
  }

  Future<MedicalConsultationDto?> pendingById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return null;
    final consultation = await _fromDrift(row);
    final status = row.syncStatus == SyncStatus.failed.name
        ? SyncStatus.fromName(row.previousSyncStatus)
        : SyncStatus.fromName(row.syncStatus);
    return MedicalConsultationDto(
      consultation: consultation.copyWith(syncStatus: status),
      syncMetadata: SyncMetadata(
        id: row.id,
        userId: row.userId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: status,
      ),
    );
  }

  Future<void> applyRemote(MedicalConsultationDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await pendingById(remote.consultation.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.inTransaction(() async {
      await _dao.upsertConsultation(
        _companion(remote.consultation, remote.syncMetadata),
      );
      await _dao.replaceExamLinks(
        userId,
        remote.consultation.id,
        remote.consultation.relatedExamIds
            .map(
              (examId) => db.MedicalConsultationExamsCompanion.insert(
                userId: userId,
                medicalConsultationId: remote.consultation.id,
                medicalExamId: examId,
              ),
            )
            .toList(growable: false),
      );
      await _dao.replaceBodyCompositionLinks(
        userId,
        remote.consultation.id,
        remote.consultation.relatedBodyCompositionIds
            .map(
              (recordId) =>
                  db.MedicalConsultationBodyCompositionsCompanion.insert(
                    userId: userId,
                    medicalConsultationId: remote.consultation.id,
                    bioimpedanceRecordId: recordId,
                  ),
            )
            .toList(growable: false),
      );
    });
  }

  Future<void> applyRemoteAndMarkSynced(MedicalConsultationDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.consultation.id);
      });

  Future<void> markSynced(String id) => _updateSync(id, SyncStatus.synced);

  Future<void> markFailed(String id, String message) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsertConsultation(
      _syncCopy(
        row,
        status: SyncStatus.failed,
        previousStatus: row.previousSyncStatus ?? row.syncStatus,
        attempts: row.syncAttempts + 1,
        error: message,
      ),
    );
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  Future<void> _updateSync(String id, SyncStatus status) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsertConsultation(_syncCopy(row, status: status, attempts: 0));
  }

  Future<MedicalConsultation> _fromDrift(db.MedicalConsultation row) async {
    final examLinks = await _dao.getExamLinks(userId, row.id);
    final bodyLinks = await _dao.getBodyCompositionLinks(userId, row.id);
    return MedicalConsultation(
      id: row.id,
      userId: row.userId,
      consultationAt: row.consultationAt,
      title: row.title,
      specialty: row.specialty,
      consultationType: MedicalConsultationType.values.byName(
        row.consultationType,
      ),
      professionalName: row.professionalName,
      professionalRegistration: row.professionalRegistration,
      clinicName: row.clinicName,
      location: row.location,
      appointmentId: row.appointmentId,
      source: MedicalConsultationSource.values.byName(row.source),
      sourceDocumentId: row.sourceDocumentId,
      reason: row.reason,
      symptoms: row.symptoms,
      patientNotes: row.patientNotes,
      professionalGuidance: row.professionalGuidance,
      dietaryGuidance: row.dietaryGuidance,
      physicalActivityGuidance: row.physicalActivityGuidance,
      supplementGuidance: row.supplementGuidance,
      medicationGuidance: row.medicationGuidance,
      requestedExamsNotes: row.requestedExamsNotes,
      followUpNotes: row.followUpNotes,
      nextAppointmentAt: row.nextAppointmentAt,
      generalNotes: row.generalNotes,
      weightKg: row.weightKg,
      heightCm: row.heightCm,
      bmi: row.bmi,
      bloodPressureSystolic: row.bloodPressureSystolic,
      bloodPressureDiastolic: row.bloodPressureDiastolic,
      heartRateBpm: row.heartRateBpm,
      waistCircumferenceCm: row.waistCircumferenceCm,
      relatedExamIds: List.unmodifiable(
        examLinks.map((item) => item.medicalExamId),
      ),
      relatedBodyCompositionIds: List.unmodifiable(
        bodyLinks.map((item) => item.bioimpedanceRecordId),
      ),
      additionalFieldsJson: row.additionalFieldsJson,
      metadataJson: row.metadataJson,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    );
  }

  db.MedicalConsultationsCompanion _companion(
    MedicalConsultation consultation,
    SyncMetadata metadata,
  ) => db.MedicalConsultationsCompanion(
    id: Value(consultation.id),
    userId: Value(userId),
    consultationAt: Value(consultation.consultationAt),
    title: Value(consultation.title),
    specialty: Value(consultation.specialty),
    consultationType: Value(consultation.consultationType.name),
    professionalName: Value(consultation.professionalName),
    professionalRegistration: Value(consultation.professionalRegistration),
    clinicName: Value(consultation.clinicName),
    location: Value(consultation.location),
    appointmentId: Value(consultation.appointmentId),
    source: Value(consultation.source.name),
    sourceDocumentId: Value(consultation.sourceDocumentId),
    reason: Value(consultation.reason),
    symptoms: Value(consultation.symptoms),
    patientNotes: Value(consultation.patientNotes),
    professionalGuidance: Value(consultation.professionalGuidance),
    dietaryGuidance: Value(consultation.dietaryGuidance),
    physicalActivityGuidance: Value(consultation.physicalActivityGuidance),
    supplementGuidance: Value(consultation.supplementGuidance),
    medicationGuidance: Value(consultation.medicationGuidance),
    requestedExamsNotes: Value(consultation.requestedExamsNotes),
    followUpNotes: Value(consultation.followUpNotes),
    nextAppointmentAt: Value(consultation.nextAppointmentAt),
    generalNotes: Value(consultation.generalNotes),
    weightKg: Value(consultation.weightKg),
    heightCm: Value(consultation.heightCm),
    bmi: Value(consultation.bmi),
    bloodPressureSystolic: Value(consultation.bloodPressureSystolic),
    bloodPressureDiastolic: Value(consultation.bloodPressureDiastolic),
    heartRateBpm: Value(consultation.heartRateBpm),
    waistCircumferenceCm: Value(consultation.waistCircumferenceCm),
    additionalFieldsJson: Value(consultation.additionalFieldsJson),
    metadataJson: Value(consultation.metadataJson),
    createdAt: Value(metadata.createdAt),
    updatedAt: Value(metadata.updatedAt),
    deletedAt: Value(metadata.deletedAt),
    syncStatus: Value(metadata.syncStatus.name),
  );

  db.MedicalConsultationsCompanion _syncCopy(
    db.MedicalConsultation row, {
    required SyncStatus status,
    String? previousStatus,
    required int attempts,
    String? error,
  }) => db.MedicalConsultationsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    consultationAt: Value(row.consultationAt),
    title: Value(row.title),
    specialty: Value(row.specialty),
    consultationType: Value(row.consultationType),
    professionalName: Value(row.professionalName),
    professionalRegistration: Value(row.professionalRegistration),
    clinicName: Value(row.clinicName),
    location: Value(row.location),
    appointmentId: Value(row.appointmentId),
    source: Value(row.source),
    sourceDocumentId: Value(row.sourceDocumentId),
    reason: Value(row.reason),
    symptoms: Value(row.symptoms),
    patientNotes: Value(row.patientNotes),
    professionalGuidance: Value(row.professionalGuidance),
    dietaryGuidance: Value(row.dietaryGuidance),
    physicalActivityGuidance: Value(row.physicalActivityGuidance),
    supplementGuidance: Value(row.supplementGuidance),
    medicationGuidance: Value(row.medicationGuidance),
    requestedExamsNotes: Value(row.requestedExamsNotes),
    followUpNotes: Value(row.followUpNotes),
    nextAppointmentAt: Value(row.nextAppointmentAt),
    generalNotes: Value(row.generalNotes),
    weightKg: Value(row.weightKg),
    heightCm: Value(row.heightCm),
    bmi: Value(row.bmi),
    bloodPressureSystolic: Value(row.bloodPressureSystolic),
    bloodPressureDiastolic: Value(row.bloodPressureDiastolic),
    heartRateBpm: Value(row.heartRateBpm),
    waistCircumferenceCm: Value(row.waistCircumferenceCm),
    additionalFieldsJson: Value(row.additionalFieldsJson),
    metadataJson: Value(row.metadataJson),
    createdAt: Value(row.createdAt),
    updatedAt: Value(_clock.now()),
    deletedAt: Value(
      status == SyncStatus.pendingDelete
          ? row.deletedAt ?? _clock.now()
          : row.deletedAt,
    ),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}

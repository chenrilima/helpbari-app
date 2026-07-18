import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';

class MedicalConsultationDto {
  const MedicalConsultationDto({
    required this.consultation,
    required this.syncMetadata,
  });

  final MedicalConsultation consultation;
  final SyncMetadata syncMetadata;

  factory MedicalConsultationDto.fromEntity(
    MedicalConsultation consultation, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    final createdAt = previousMetadata?.createdAt ?? consultation.createdAt;
    final deletedAt = consultation.deletedAt;
    final previousStatus = previousMetadata?.syncStatus;
    final nextStatus = deletedAt != null
        ? SyncStatus.pendingDelete
        : previousStatus == null
        ? SyncStatus.pendingCreate
        : previousStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;
    return MedicalConsultationDto(
      consultation: consultation.copyWith(
        updatedAt: now,
        deletedAt: deletedAt,
        syncStatus: nextStatus,
      ),
      syncMetadata: SyncMetadata(
        id: consultation.id,
        userId: consultation.userId,
        createdAt: createdAt,
        updatedAt: now,
        deletedAt: deletedAt,
        syncStatus: nextStatus,
      ),
    );
  }

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': consultation.id,
    'user_id': userId,
    'consultation_at': consultation.consultationAt.toUtc().toIso8601String(),
    'title': consultation.title,
    'specialty': consultation.specialty,
    'consultation_type': consultation.consultationType.name,
    'professional_name': consultation.professionalName,
    'professional_registration': consultation.professionalRegistration,
    'clinic_name': consultation.clinicName,
    'location': consultation.location,
    'appointment_id': consultation.appointmentId,
    'source': consultation.source.name,
    'source_document_id': consultation.sourceDocumentId,
    'reason': consultation.reason,
    'symptoms': consultation.symptoms,
    'patient_notes': consultation.patientNotes,
    'professional_guidance': consultation.professionalGuidance,
    'dietary_guidance': consultation.dietaryGuidance,
    'physical_activity_guidance': consultation.physicalActivityGuidance,
    'supplement_guidance': consultation.supplementGuidance,
    'medication_guidance': consultation.medicationGuidance,
    'requested_exams_notes': consultation.requestedExamsNotes,
    'follow_up_notes': consultation.followUpNotes,
    'next_appointment_at': consultation.nextAppointmentAt
        ?.toUtc()
        .toIso8601String(),
    'general_notes': consultation.generalNotes,
    'weight_kg': consultation.weightKg,
    'height_cm': consultation.heightCm,
    'bmi': consultation.bmi,
    'blood_pressure_systolic': consultation.bloodPressureSystolic,
    'blood_pressure_diastolic': consultation.bloodPressureDiastolic,
    'heart_rate_bpm': consultation.heartRateBpm,
    'waist_circumference_cm': consultation.waistCircumferenceCm,
    'additional_fields_json': consultation.additionalFieldsJson,
    'metadata_json': consultation.metadataJson,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  factory MedicalConsultationDto.fromSupabaseRow(
    Map<String, dynamic> row, {
    List<String> relatedExamIds = const <String>[],
    List<String> relatedBodyCompositionIds = const <String>[],
  }) {
    final deletedAt = row['deleted_at'] == null
        ? null
        : DateTime.parse(row['deleted_at'] as String).toUtc();
    final syncStatus = deletedAt != null
        ? SyncStatus.pendingDelete
        : SyncStatus.synced;
    final consultation = MedicalConsultation(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      consultationAt: DateTime.parse(row['consultation_at'] as String).toUtc(),
      title: row['title'] as String?,
      specialty: row['specialty'] as String?,
      consultationType: MedicalConsultationType.values.byName(
        (row['consultation_type'] as String?) ?? 'unknown',
      ),
      professionalName: row['professional_name'] as String?,
      professionalRegistration: row['professional_registration'] as String?,
      clinicName: row['clinic_name'] as String?,
      location: row['location'] as String?,
      appointmentId: row['appointment_id'] as String?,
      source: MedicalConsultationSource.values.byName(
        (row['source'] as String?) ?? 'unknown',
      ),
      sourceDocumentId: row['source_document_id'] as String?,
      reason: row['reason'] as String?,
      symptoms: row['symptoms'] as String?,
      patientNotes: row['patient_notes'] as String?,
      professionalGuidance: row['professional_guidance'] as String?,
      dietaryGuidance: row['dietary_guidance'] as String?,
      physicalActivityGuidance: row['physical_activity_guidance'] as String?,
      supplementGuidance: row['supplement_guidance'] as String?,
      medicationGuidance: row['medication_guidance'] as String?,
      requestedExamsNotes: row['requested_exams_notes'] as String?,
      followUpNotes: row['follow_up_notes'] as String?,
      nextAppointmentAt: row['next_appointment_at'] == null
          ? null
          : DateTime.parse(row['next_appointment_at'] as String).toUtc(),
      generalNotes: row['general_notes'] as String?,
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
      heightCm: (row['height_cm'] as num?)?.toDouble(),
      bmi: (row['bmi'] as num?)?.toDouble(),
      bloodPressureSystolic: row['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: row['blood_pressure_diastolic'] as int?,
      heartRateBpm: row['heart_rate_bpm'] as int?,
      waistCircumferenceCm: (row['waist_circumference_cm'] as num?)?.toDouble(),
      relatedExamIds: List.unmodifiable(relatedExamIds),
      relatedBodyCompositionIds: List.unmodifiable(relatedBodyCompositionIds),
      additionalFieldsJson: row['additional_fields_json'] as String?,
      metadataJson: row['metadata_json'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      deletedAt: deletedAt,
      syncStatus: syncStatus,
    );
    return MedicalConsultationDto(
      consultation: consultation,
      syncMetadata: SyncMetadata(
        id: consultation.id,
        userId: consultation.userId,
        createdAt: consultation.createdAt,
        updatedAt: consultation.updatedAt,
        deletedAt: consultation.deletedAt,
        syncStatus: syncStatus,
      ),
    );
  }
}

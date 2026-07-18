import '../../../../core/sync/sync.dart';

enum MedicalConsultationType {
  surgeon,
  nutritionist,
  psychologist,
  endocrinologist,
  generalPractitioner,
  physiotherapist,
  physicalEducator,
  nursing,
  multidisciplinary,
  emergency,
  other,
  unknown,
}

enum MedicalConsultationSource {
  manual,
  appointment,
  document,
  imported,
  professionalPortal,
  unknown,
}

class MedicalConsultation {
  const MedicalConsultation({
    required this.id,
    required this.userId,
    required this.consultationAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.title,
    this.specialty,
    this.consultationType = MedicalConsultationType.unknown,
    this.professionalName,
    this.professionalRegistration,
    this.clinicName,
    this.location,
    this.appointmentId,
    this.sourceDocumentId,
    this.reason,
    this.symptoms,
    this.patientNotes,
    this.professionalGuidance,
    this.dietaryGuidance,
    this.physicalActivityGuidance,
    this.supplementGuidance,
    this.medicationGuidance,
    this.requestedExamsNotes,
    this.followUpNotes,
    this.nextAppointmentAt,
    this.generalNotes,
    this.weightKg,
    this.heightCm,
    this.bmi,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRateBpm,
    this.waistCircumferenceCm,
    this.relatedExamIds = const <String>[],
    this.relatedBodyCompositionIds = const <String>[],
    this.additionalFieldsJson,
    this.metadataJson,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final DateTime consultationAt;
  final String? title;
  final String? specialty;
  final MedicalConsultationType consultationType;
  final String? professionalName;
  final String? professionalRegistration;
  final String? clinicName;
  final String? location;
  final String? appointmentId;
  final MedicalConsultationSource source;
  final String? sourceDocumentId;
  final String? reason;
  final String? symptoms;
  final String? patientNotes;
  final String? professionalGuidance;
  final String? dietaryGuidance;
  final String? physicalActivityGuidance;
  final String? supplementGuidance;
  final String? medicationGuidance;
  final String? requestedExamsNotes;
  final String? followUpNotes;
  final DateTime? nextAppointmentAt;
  final String? generalNotes;
  final double? weightKg;
  final double? heightCm;
  final double? bmi;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRateBpm;
  final double? waistCircumferenceCm;
  final List<String> relatedExamIds;
  final List<String> relatedBodyCompositionIds;
  final String? additionalFieldsJson;
  final String? metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get hasAnyContent {
    bool filled(String? value) => value?.trim().isNotEmpty == true;
    return filled(title) ||
        filled(professionalName) ||
        filled(reason) ||
        filled(symptoms) ||
        filled(patientNotes) ||
        filled(professionalGuidance) ||
        filled(dietaryGuidance) ||
        filled(physicalActivityGuidance) ||
        filled(supplementGuidance) ||
        filled(medicationGuidance) ||
        filled(requestedExamsNotes) ||
        filled(followUpNotes) ||
        filled(generalNotes) ||
        appointmentId?.trim().isNotEmpty == true ||
        sourceDocumentId?.trim().isNotEmpty == true ||
        weightKg != null ||
        heightCm != null ||
        bmi != null ||
        bloodPressureSystolic != null ||
        bloodPressureDiastolic != null ||
        heartRateBpm != null ||
        waistCircumferenceCm != null ||
        relatedExamIds.isNotEmpty ||
        relatedBodyCompositionIds.isNotEmpty;
  }

  bool get isLinkedToAppointment => appointmentId?.trim().isNotEmpty == true;

  MedicalConsultation copyWith({
    DateTime? consultationAt,
    String? title,
    String? specialty,
    MedicalConsultationType? consultationType,
    String? professionalName,
    String? professionalRegistration,
    String? clinicName,
    String? location,
    String? appointmentId,
    MedicalConsultationSource? source,
    String? sourceDocumentId,
    String? reason,
    String? symptoms,
    String? patientNotes,
    String? professionalGuidance,
    String? dietaryGuidance,
    String? physicalActivityGuidance,
    String? supplementGuidance,
    String? medicationGuidance,
    String? requestedExamsNotes,
    String? followUpNotes,
    DateTime? nextAppointmentAt,
    String? generalNotes,
    double? weightKg,
    double? heightCm,
    double? bmi,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    int? heartRateBpm,
    double? waistCircumferenceCm,
    List<String>? relatedExamIds,
    List<String>? relatedBodyCompositionIds,
    String? additionalFieldsJson,
    String? metadataJson,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => MedicalConsultation(
    id: id,
    userId: userId,
    consultationAt: consultationAt ?? this.consultationAt,
    title: title ?? this.title,
    specialty: specialty ?? this.specialty,
    consultationType: consultationType ?? this.consultationType,
    professionalName: professionalName ?? this.professionalName,
    professionalRegistration:
        professionalRegistration ?? this.professionalRegistration,
    clinicName: clinicName ?? this.clinicName,
    location: location ?? this.location,
    appointmentId: appointmentId ?? this.appointmentId,
    source: source ?? this.source,
    sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
    reason: reason ?? this.reason,
    symptoms: symptoms ?? this.symptoms,
    patientNotes: patientNotes ?? this.patientNotes,
    professionalGuidance: professionalGuidance ?? this.professionalGuidance,
    dietaryGuidance: dietaryGuidance ?? this.dietaryGuidance,
    physicalActivityGuidance:
        physicalActivityGuidance ?? this.physicalActivityGuidance,
    supplementGuidance: supplementGuidance ?? this.supplementGuidance,
    medicationGuidance: medicationGuidance ?? this.medicationGuidance,
    requestedExamsNotes: requestedExamsNotes ?? this.requestedExamsNotes,
    followUpNotes: followUpNotes ?? this.followUpNotes,
    nextAppointmentAt: nextAppointmentAt ?? this.nextAppointmentAt,
    generalNotes: generalNotes ?? this.generalNotes,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    bmi: bmi ?? this.bmi,
    bloodPressureSystolic: bloodPressureSystolic ?? this.bloodPressureSystolic,
    bloodPressureDiastolic:
        bloodPressureDiastolic ?? this.bloodPressureDiastolic,
    heartRateBpm: heartRateBpm ?? this.heartRateBpm,
    waistCircumferenceCm: waistCircumferenceCm ?? this.waistCircumferenceCm,
    relatedExamIds: relatedExamIds ?? this.relatedExamIds,
    relatedBodyCompositionIds:
        relatedBodyCompositionIds ?? this.relatedBodyCompositionIds,
    additionalFieldsJson: additionalFieldsJson ?? this.additionalFieldsJson,
    metadataJson: metadataJson ?? this.metadataJson,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

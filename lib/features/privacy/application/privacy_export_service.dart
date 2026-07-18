import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../core/services/services.dart';
import '../../medical_reports/domain/models/models.dart';
import '../../settings/domain/entities/entities.dart';
import '../domain/models/models.dart';

class PrivacyExportService {
  const PrivacyExportService({
    required Future<MedicalReportSnapshot> Function() loadReport,
    required Future<AppSettings> Function() loadSettings,
    required Future<List<dynamic>> Function(DateTime start, DateTime end)
    loadVitaminLogs,
    required Future<List<dynamic>> Function(DateTime start, DateTime end)
    loadMedicationLogs,
    required ClockService clock,
    required String userId,
  }) : _loadReport = loadReport,
       _loadSettings = loadSettings,
       _loadVitaminLogs = loadVitaminLogs,
       _loadMedicationLogs = loadMedicationLogs,
       _clock = clock,
       _userId = userId;

  final Future<MedicalReportSnapshot> Function() _loadReport;
  final Future<AppSettings> Function() _loadSettings;
  final Future<List<dynamic>> Function(DateTime start, DateTime end)
  _loadVitaminLogs;
  final Future<List<dynamic>> Function(DateTime start, DateTime end)
  _loadMedicationLogs;
  final ClockService _clock;
  final String _userId;

  Future<PrivacyExportPackage> generate() async {
    if (_userId == 'anonymous') {
      throw StateError('Usuário autenticado obrigatório para exportação.');
    }
    final now = _clock.now();
    final results = await Future.wait<dynamic>([
      _loadReport(),
      _loadSettings(),
      _loadVitaminLogs(DateTime(2000), now),
      _loadMedicationLogs(DateTime(2000), now),
    ]);
    final snapshot = results[0];
    final settings = results[1];
    final vitaminLogs = results[2] as List;
    final medicationLogs = results[3] as List;
    final profile = snapshot.profile;
    final data = <String, Object?>{
      'metadata': {
        'format': 'helpbari-user-export',
        'version': '1.0',
        'generatedAt': now.toUtc().toIso8601String(),
        'userId': _userId,
      },
      'profile': profile == null
          ? null
          : {
              'id': profile.id,
              'name': profile.name,
              'email': profile.email,
              'birthDate': profile.birthDate.value.toIso8601String(),
              'heightCm': profile.height.value,
              'initialWeightKg': profile.initialWeight.value,
              'targetWeightKg': profile.targetWeight?.value,
              'surgeryDate': profile.surgeryDate.value.toIso8601String(),
              'surgeryType': profile.surgeryType.name,
              'photoStoragePath': profile.photoStoragePath,
              'createdAt': profile.createdAt.value.toIso8601String(),
            },
      'settings': {
        'dailyWaterGoalMl': settings.dailyWaterGoalMl,
        'vitaminRemindersEnabled': settings.vitaminRemindersEnabled,
        'medicationRemindersEnabled': settings.medicationRemindersEnabled,
        'appointmentRemindersEnabled': settings.appointmentRemindersEnabled,
        'mealTrackingEnabled': settings.mealTrackingEnabled,
        'weightUnit': settings.weightUnit,
      },
      'water': [
        for (final record in snapshot.waterHistory)
          {
            'id': record.id,
            'amountMl': record.amount.valueInMl,
            'recordedAt': record.recordedAt.toIso8601String(),
          },
      ],
      'weight': [
        for (final record in snapshot.weightHistory)
          {
            'id': record.id,
            'weightKg': record.weight.value,
            'recordedAt': record.recordedAt.value.toIso8601String(),
            'notes': record.notes?.value,
          },
      ],
      'meals': [
        for (final meal in snapshot.meals)
          {
            'id': meal.id,
            'name': meal.name.value,
            'type': meal.type.name,
            'date': meal.mealDate.value.toIso8601String(),
            'proteinGrams': meal.proteinGrams,
            'notes': meal.notes,
          },
      ],
      'vitamins': [
        for (final vitamin in snapshot.vitamins)
          {
            'id': vitamin.id,
            'name': vitamin.name.value,
            'hour': vitamin.scheduleTime.hour,
            'minute': vitamin.scheduleTime.minute,
          },
      ],
      'vitaminLogs': [
        for (final log in vitaminLogs)
          {
            'id': log.id,
            'vitaminId': log.vitaminId,
            'date': log.date.toIso8601String(),
            'status': log.status.name,
          },
      ],
      'medications': [
        for (final medication in snapshot.medications)
          {
            'id': medication.id,
            'name': medication.name.value,
            'hour': medication.scheduleTime.hour,
            'minute': medication.scheduleTime.minute,
            'dosage': medication.dosage,
            'notes': medication.notes,
          },
      ],
      'medicationLogs': [
        for (final log in medicationLogs)
          {
            'id': log.id,
            'medicationId': log.medicationId,
            'date': log.date.toIso8601String(),
            'status': log.status.name,
          },
      ],
      'appointments': [
        for (final appointment in snapshot.appointments)
          {
            'id': appointment.id,
            'title': appointment.title,
            'date': appointment.date.value.toIso8601String(),
            'doctorName': appointment.doctorName,
            'location': appointment.location,
            'notes': appointment.notes,
            'status': appointment.status.name,
          },
      ],
      'medicalConsultations': [
        for (final consultation in snapshot.consultations)
          {
            'id': consultation.id,
            'consultationAt': consultation.consultationAt.toIso8601String(),
            'title': consultation.title,
            'specialty': consultation.specialty,
            'consultationType': _enumName(consultation.consultationType),
            'professionalName': consultation.professionalName,
            'professionalRegistration': consultation.professionalRegistration,
            'clinicName': consultation.clinicName,
            'location': consultation.location,
            'appointmentId': consultation.appointmentId,
            'source': _enumName(consultation.source),
            'sourceDocumentId': consultation.sourceDocumentId,
            'reason': consultation.reason,
            'symptoms': consultation.symptoms,
            'patientNotes': consultation.patientNotes,
            'professionalGuidance': consultation.professionalGuidance,
            'dietaryGuidance': consultation.dietaryGuidance,
            'physicalActivityGuidance': consultation.physicalActivityGuidance,
            'supplementGuidance': consultation.supplementGuidance,
            'medicationGuidance': consultation.medicationGuidance,
            'requestedExamsNotes': consultation.requestedExamsNotes,
            'followUpNotes': consultation.followUpNotes,
            'nextAppointmentAt': consultation.nextAppointmentAt
                ?.toIso8601String(),
            'generalNotes': consultation.generalNotes,
            'weightKg': consultation.weightKg,
            'heightCm': consultation.heightCm,
            'bmi': consultation.bmi,
            'bloodPressureSystolic': consultation.bloodPressureSystolic,
            'bloodPressureDiastolic': consultation.bloodPressureDiastolic,
            'heartRateBpm': consultation.heartRateBpm,
            'waistCircumferenceCm': consultation.waistCircumferenceCm,
            'relatedExamIds': consultation.relatedExamIds,
            'relatedBodyCompositionIds': consultation.relatedBodyCompositionIds,
            'createdAt': consultation.createdAt.toIso8601String(),
            'updatedAt': consultation.updatedAt.toIso8601String(),
            'deletedAt': consultation.deletedAt?.toIso8601String(),
            'syncStatus': _enumName(consultation.syncStatus),
          },
      ],
      'medicalExams': [
        for (final exam in snapshot.exams)
          {
            'id': exam.id,
            'title': exam.title,
            'performedAt': exam.performedAt.toIso8601String(),
            'collectedAt': exam.collectedAt?.toIso8601String(),
            'receivedAt': exam.receivedAt?.toIso8601String(),
            'laboratoryName': exam.laboratoryName,
            'professionalName': exam.professionalName,
            'requestProfessionalName': exam.requestProfessionalName,
            'documentNumber': exam.documentNumber,
            'notes': exam.notes,
            'source': _enumName(exam.source),
            'sourceDocumentId': exam.sourceDocumentId,
            'legacyAttachmentPath': exam.legacyAttachmentPath,
            'createdAt': exam.createdAt.toIso8601String(),
            'updatedAt': exam.updatedAt.toIso8601String(),
            'deletedAt': exam.deletedAt?.toIso8601String(),
            'syncStatus': _enumName(exam.syncStatus),
            'results': [
              for (final result in exam.results.where(
                (item) => item.deletedAt == null,
              ))
                {
                  'id': result.id,
                  'name': result.displayName,
                  'canonicalCode': result.canonicalCode,
                  'canonicalName': result.canonicalName,
                  'valueType': _enumName(result.valueType),
                  'numericValue': result.numericValue,
                  'textValue': result.textValue,
                  'booleanValue': result.booleanValue,
                  'qualitativeValue': result.qualitativeValue,
                  'unit': result.unit,
                  'normalizedUnit': result.normalizedUnit,
                  'referenceRangeText': result.referenceRangeText,
                  'referenceMin': result.referenceMin,
                  'referenceMax': result.referenceMax,
                  'referenceContext': result.referenceContext,
                  'notes': result.notes,
                  'source': _enumName(result.source),
                  'createdAt': result.createdAt.toIso8601String(),
                  'updatedAt': result.updatedAt.toIso8601String(),
                  'deletedAt': result.deletedAt?.toIso8601String(),
                  'syncStatus': _enumName(result.syncStatus),
                },
            ],
          },
      ],
      'reports': [
        {
          'version': snapshot.reportVersion,
          'generatedAt': snapshot.generatedAt.toIso8601String(),
          'periodStart': snapshot.periodStart.toIso8601String(),
          'automaticObservations': snapshot.automaticObservations,
          'attachments': [
            for (final attachment in snapshot.attachments)
              {
                'name': attachment.name,
                'type': attachment.type.name,
                'path': attachment.path,
              },
          ],
        },
      ],
    };
    final encoded = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    final archive = Archive()
      ..addFile(ArchiveFile('helpbari-data.json', encoded.length, encoded));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final counts = <String, int>{
      'water': snapshot.waterHistory.length,
      'weight': snapshot.weightHistory.length,
      'meals': snapshot.meals.length,
      'vitamins': snapshot.vitamins.length,
      'medications': snapshot.medications.length,
      'appointments': snapshot.appointments.length,
      'medicalConsultations': snapshot.consultations.length,
      'medicalExams': snapshot.exams.length,
      'reports': 1,
    };
    return PrivacyExportPackage(
      fileName:
          'helpbari-meus-dados-${now.toIso8601String().substring(0, 10)}.zip',
      bytes: bytes,
      generatedAt: now,
      categoryCounts: counts,
    );
  }

  String _enumName(Object value) => value.toString().split('.').last;
}

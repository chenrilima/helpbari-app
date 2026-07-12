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
      'exams': [
        for (final exam in snapshot.exams)
          {
            'id': exam.id,
            'name': exam.name.value,
            'date': exam.examDate.value.toIso8601String(),
            'laboratory': exam.laboratory,
            'notes': exam.notes,
            'attachmentPath': exam.attachmentPath,
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
      'exams': snapshot.exams.length,
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
}

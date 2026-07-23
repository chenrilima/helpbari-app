import 'dart:convert';

import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';

class MedicalPrescriptionDto {
  const MedicalPrescriptionDto({
    required this.prescription,
    required this.metadata,
  });

  final MedicalPrescription prescription;
  final SyncMetadata metadata;

  Map<String, dynamic> toSupabasePrescriptionRow() => {
    'id': prescription.id,
    'user_id': prescription.userId,
    'professional_name': prescription.professionalName,
    'professional_specialty': prescription.professionalSpecialty,
    'professional_registration': prescription.professionalRegistration,
    'prescribed_at': prescription.prescribedAt.toUtc().toIso8601String(),
    'valid_until': prescription.validUntil?.toUtc().toIso8601String(),
    'notes': prescription.notes,
    'source_document_id': prescription.sourceDocumentId,
    'status': prescription.status.name,
    'created_at': metadata.createdAt.toUtc().toIso8601String(),
    'updated_at': metadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': metadata.deletedAt?.toUtc().toIso8601String(),
  };

  List<Map<String, dynamic>> toSupabaseItemRows() => prescription.items
      .map(
        (item) => {
          'id': item.id,
          'prescription_id': prescription.id,
          'user_id': prescription.userId,
          'item_type': item.itemType.name,
          'name': item.name,
          'dosage_value': item.dosageValue,
          'dosage_unit': item.dosageUnit,
          'route': item.route,
          'frequency_type': item.frequencyType?.name,
          'frequency_value': item.frequencyValue,
          'frequency_unit': item.frequencyUnit,
          'schedule_times': item.scheduleTimes,
          'days_of_week': item.daysOfWeek,
          'interval_days': item.intervalDays,
          'start_date': item.startDate?.toUtc().toIso8601String(),
          'end_date': item.endDate?.toUtc().toIso8601String(),
          'duration_value': item.durationValue,
          'duration_unit': item.durationUnit,
          'instructions': item.instructions,
          'as_needed': item.asNeeded,
          'notes': item.notes,
          'confidence': item.confidence,
          'field_confidences': item.fieldConfidences,
          'provenance': item.provenance,
          'review_status': item.reviewStatus.name,
          'linked_medication_id': item.linkedMedicationId,
          'linked_vitamin_id': item.linkedVitaminId,
          'created_at': item.createdAt.toUtc().toIso8601String(),
          'updated_at': item.updatedAt.toUtc().toIso8601String(),
          'deleted_at': item.deletedAt?.toUtc().toIso8601String(),
        },
      )
      .toList(growable: false);

  factory MedicalPrescriptionDto.fromSupabaseRows({
    required Map<String, dynamic> prescription,
    required List<Map<String, dynamic>> items,
  }) {
    final status = prescription['deleted_at'] == null
        ? SyncStatus.synced
        : SyncStatus.pendingDelete;
    final entity = MedicalPrescription(
      id: prescription['id'] as String,
      userId: prescription['user_id'] as String,
      professionalName: prescription['professional_name'] as String?,
      professionalSpecialty: prescription['professional_specialty'] as String?,
      professionalRegistration:
          prescription['professional_registration'] as String?,
      prescribedAt: DateTime.parse(prescription['prescribed_at'] as String),
      validUntil: _date(prescription['valid_until']),
      notes: prescription['notes'] as String?,
      sourceDocumentId: prescription['source_document_id'] as String?,
      status: MedicalPrescriptionStatus.values.byName(
        prescription['status'] as String,
      ),
      items: items.map(_itemFromRow).toList(growable: false),
      createdAt: DateTime.parse(prescription['created_at'] as String),
      updatedAt: DateTime.parse(prescription['updated_at'] as String),
      deletedAt: _date(prescription['deleted_at']),
      syncStatus: status,
    );
    return MedicalPrescriptionDto(
      prescription: entity,
      metadata: SyncMetadata(
        id: entity.id,
        userId: entity.userId,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        deletedAt: entity.deletedAt,
        syncStatus: status,
        serverRevision: prescription['server_revision'] as int?,
      ),
    );
  }

  static MedicalPrescriptionItem _itemFromRow(Map<String, dynamic> row) =>
      MedicalPrescriptionItem(
        id: row['id'] as String,
        prescriptionId: row['prescription_id'] as String,
        userId: row['user_id'] as String,
        itemType: PrescriptionItemType.values.byName(
          row['item_type'] as String,
        ),
        name: row['name'] as String,
        dosageValue: (row['dosage_value'] as num?)?.toDouble(),
        dosageUnit: row['dosage_unit'] as String?,
        route: row['route'] as String?,
        frequencyType: row['frequency_type'] == null
            ? null
            : PrescriptionFrequencyType.values.byName(
                row['frequency_type'] as String,
              ),
        frequencyValue: row['frequency_value'] as int?,
        frequencyUnit: row['frequency_unit'] as String?,
        scheduleTimes: _stringList(row['schedule_times']),
        daysOfWeek: _intList(row['days_of_week']),
        intervalDays: row['interval_days'] as int?,
        startDate: _date(row['start_date']),
        endDate: _date(row['end_date']),
        durationValue: row['duration_value'] as int?,
        durationUnit: row['duration_unit'] as String?,
        instructions: row['instructions'] as String?,
        asNeeded: row['as_needed'] as bool? ?? false,
        notes: row['notes'] as String?,
        confidence: (row['confidence'] as num?)?.toDouble(),
        fieldConfidences: _doubleMap(row['field_confidences']),
        provenance: _stringMap(row['provenance']),
        reviewStatus: PrescriptionReviewStatus.values.byName(
          row['review_status'] as String,
        ),
        linkedMedicationId: row['linked_medication_id'] as String?,
        linkedVitaminId: row['linked_vitamin_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: _date(row['deleted_at']),
        syncStatus: SyncStatus.synced,
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
  static List<String> _stringList(Object? value) => value is String
      ? (jsonDecode(value) as List).cast<String>()
      : (value as List? ?? const []).cast<String>();
  static List<int> _intList(Object? value) => value is String
      ? (jsonDecode(value) as List).cast<int>()
      : (value as List? ?? const []).cast<int>();
  static Map<String, double> _doubleMap(Object? value) {
    final raw = value is String ? jsonDecode(value) : value;
    return (raw as Map? ?? const {}).map(
      (key, item) => MapEntry(key as String, (item as num).toDouble()),
    );
  }

  static Map<String, String> _stringMap(Object? value) {
    final raw = value is String ? jsonDecode(value) : value;
    return (raw as Map? ?? const {}).cast<String, String>();
  }
}

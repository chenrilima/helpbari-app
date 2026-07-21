import 'package:uuid/uuid.dart';

import '../../../core/sync/sync.dart';
import '../../medical_prescriptions/domain/entities/entities.dart';
import '../../medical_prescriptions/domain/repositories/prescription_platform_repository.dart';
import '../domain/entities/document_models.dart';

class PrescriptionImportPreview {
  const PrescriptionImportPreview({
    required this.prescription,
    required this.processingId,
    required this.requiresReview,
    required this.uncertainFieldKeys,
  });

  final MedicalPrescription prescription;
  final String processingId;
  final bool requiresReview;
  final Set<String> uncertainFieldKeys;
}

class PrescriptionImportOrchestrator {
  const PrescriptionImportOrchestrator({
    required this.platform,
    this.uuid = const Uuid(),
  });

  final PrescriptionPlatformRepository platform;
  final Uuid uuid;
  static const _identityNamespace = 'a36a4df4-c02c-55ad-9d9e-c7bb305242d4';

  PrescriptionImportPreview preview({
    required String userId,
    required DocumentProcessing processing,
    required List<ExtractedField> fields,
    required DateTime now,
  }) {
    if (processing.detectedType != DetectedDocumentType.prescription) {
      throw StateError('Document is not a prescription.');
    }
    final values = <String, List<ExtractedField>>{};
    for (final field in fields.where(
      (value) => value.status != FieldStatus.ignored,
    )) {
      values.putIfAbsent(field.key, () => <ExtractedField>[]).add(field);
    }
    String? value(String key) =>
        values[key]?.firstOrNull?.confirmedValue ??
        values[key]?.firstOrNull?.normalizedValue ??
        values[key]?.firstOrNull?.rawValue;
    final indexes =
        fields
            .map(
              (field) =>
                  RegExp(r'^item_(\d+)\.').firstMatch(field.key)?.group(1),
            )
            .whereType<String>()
            .map(int.parse)
            .toSet()
            .toList()
          ..sort();
    final prescriptionId = uuid.v5(
      _identityNamespace,
      'prescription-document|$userId|${processing.documentId}',
    );
    final items = <MedicalPrescriptionItem>[];
    for (final index in indexes) {
      final prefix = 'item_$index';
      final name = value('$prefix.name')?.trim();
      if (name == null || name.isEmpty) continue;
      final itemFields = fields
          .where((field) => field.key.startsWith('$prefix.'))
          .toList();
      final times =
          values['$prefix.schedule_time']
              ?.map(
                (field) =>
                    field.confirmedValue ??
                    field.normalizedValue ??
                    field.rawValue,
              )
              .toSet()
              .toList() ??
          const <String>[];
      items.add(
        MedicalPrescriptionItem(
          id: uuid.v5(
            _identityNamespace,
            'prescription-item|$prescriptionId|$index',
          ),
          prescriptionId: prescriptionId,
          userId: userId,
          itemType: _itemType(value('$prefix.item_type')),
          name: name,
          dosageValue: double.tryParse(
            (value('$prefix.dosage_value') ?? '').replaceAll(',', '.'),
          ),
          dosageUnit: value('$prefix.dosage_unit'),
          frequencyType: _frequency(value('$prefix.frequency_type')),
          frequencyValue: int.tryParse(value('$prefix.frequency_value') ?? ''),
          scheduleTimes: times,
          durationValue: int.tryParse(value('$prefix.duration_value') ?? ''),
          durationUnit: value('$prefix.duration_unit'),
          instructions: value('$prefix.instructions'),
          asNeeded: value('$prefix.as_needed') == 'true',
          confidence: itemFields.isEmpty
              ? null
              : itemFields
                    .map((field) => field.confidence)
                    .reduce((a, b) => a < b ? a : b),
          fieldConfidences: {
            for (final field in itemFields) field.key: field.confidence,
          },
          provenance: {
            for (final field in itemFields)
              field.key:
                  '${field.source.name}:${field.id}'
                  '${field.confirmedValue == null ? '' : '|humanConfirmed'}',
          },
          reviewStatus: PrescriptionReviewStatus.pending,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
        ),
      );
    }
    final uncertain = fields
        .where(
          (field) =>
              field.status == FieldStatus.uncertain || field.confidence < .8,
        )
        .map((field) => field.key)
        .toSet();
    final prescription = MedicalPrescription(
      id: prescriptionId,
      userId: userId,
      professionalName: value('professional_name'),
      professionalSpecialty: value('professional_specialty'),
      professionalRegistration: value('professional_registration'),
      prescribedAt: _date(value('prescribed_at')) ?? now,
      validUntil: _date(value('valid_until')),
      sourceDocumentId: processing.documentId,
      status: uncertain.isEmpty
          ? MedicalPrescriptionStatus.draft
          : MedicalPrescriptionStatus.requiresReview,
      items: items,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );
    return PrescriptionImportPreview(
      prescription: prescription,
      processingId: processing.id,
      requiresReview: uncertain.isNotEmpty,
      uncertainFieldKeys: uncertain,
    );
  }

  Future<PrescriptionVersion> savePreview(PrescriptionImportPreview preview) =>
      platform.createDraftVersion(
        snapshot: preview.prescription,
        sourceProcessingId: preview.processingId,
      );

  PrescriptionItemType _itemType(String? value) => switch (value) {
    'medication' => PrescriptionItemType.medication,
    'vitamin' => PrescriptionItemType.vitamin,
    'supplement' => PrescriptionItemType.supplement,
    _ => PrescriptionItemType.other,
  };

  PrescriptionFrequencyType? _frequency(String? value) => value == null
      ? null
      : PrescriptionFrequencyType.values
            .where((item) => item.name == value)
            .firstOrNull;

  DateTime? _date(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalized.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      var year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(value);
  }
}

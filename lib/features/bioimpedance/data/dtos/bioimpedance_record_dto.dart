import 'dart:convert';

import '../../../../core/sync/sync.dart';
import '../../domain/entities/bioimpedance_record.dart';

class BioimpedanceRecordDto {
  const BioimpedanceRecordDto({
    required this.record,
    required this.syncMetadata,
  });

  final BioimpedanceRecord record;
  final SyncMetadata syncMetadata;

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': record.id,
    'user_id': userId,
    'measured_at': record.measuredAt.toUtc().toIso8601String(),
    'weight_kg': record.weightKg,
    'muscle_mass_kg': record.muscleMassKg,
    'body_fat_mass_kg': record.bodyFatMassKg,
    'body_water_percentage': record.bodyWaterPercentage,
    'body_fat_percentage': record.bodyFatPercentage,
    'skeletal_muscle_mass_kg': record.skeletalMuscleMassKg,
    'lean_body_mass_kg': record.leanBodyMassKg,
    'fat_free_mass_kg': record.fatFreeMassKg,
    'visceral_fat_level': record.visceralFatLevel,
    'visceral_fat_area_cm2': record.visceralFatAreaCm2,
    'subcutaneous_fat_percentage': record.subcutaneousFatPercentage,
    'protein_percentage': record.proteinPercentage,
    'mineral_mass_kg': record.mineralMassKg,
    'bone_mass_kg': record.boneMassKg,
    'bmi': record.bmi,
    'basal_metabolic_rate_kcal': record.basalMetabolicRateKcal,
    'metabolic_age': record.metabolicAge,
    'waist_hip_ratio': record.waistHipRatio,
    'waist_circumference_cm': record.waistCircumferenceCm,
    'hip_circumference_cm': record.hipCircumferenceCm,
    'body_cell_mass_kg': record.bodyCellMassKg,
    'intracellular_water_liters': record.intracellularWaterLiters,
    'extracellular_water_liters': record.extracellularWaterLiters,
    'total_body_water_liters': record.totalBodyWaterLiters,
    'phase_angle_degrees': record.phaseAngleDegrees,
    'body_score': record.bodyScore,
    'recommended_weight_kg': record.recommendedWeightKg,
    'weight_control_kg': record.weightControlKg,
    'fat_control_kg': record.fatControlKg,
    'muscle_control_kg': record.muscleControlKg,
    'device_name': record.deviceName,
    'clinic_name': record.clinicName,
    'professional_name': record.professionalName,
    'notes': record.notes,
    'source_document_id': record.sourceDocumentId,
    'source': record.source.name,
    'additional_metrics': _metricsJsonObject(record.additionalMetrics),
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  factory BioimpedanceRecordDto.fromEntity(
    BioimpedanceRecord record, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return BioimpedanceRecordDto(
      record: record,
      syncMetadata: SyncMetadata(
        id: record.id,
        userId: record.userId,
        createdAt: previousMetadata?.createdAt ?? record.createdAt,
        updatedAt: now,
        deletedAt: record.deletedAt,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  factory BioimpedanceRecordDto.fromSupabaseRow(Map<String, dynamic> row) {
    final metadata = SyncMetadata(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String),
      syncStatus: SyncStatus.synced,
    );
    return BioimpedanceRecordDto(
      syncMetadata: metadata,
      record: _record(row, metadata),
    );
  }

  static BioimpedanceRecord fromRowLike(Map<String, dynamic> row) {
    final metadata = SyncMetadata(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
      deletedAt: row['deleted_at'] as DateTime?,
      syncStatus: SyncStatus.fromName(row['sync_status'] as String?),
    );
    return _record(row, metadata);
  }

  static BioimpedanceRecord _record(
    Map<String, dynamic> row,
    SyncMetadata metadata,
  ) => BioimpedanceRecord(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    measuredAt: _date(row['measured_at'])!,
    weightKg: _double(row['weight_kg']),
    muscleMassKg: _double(row['muscle_mass_kg']),
    bodyFatMassKg: _double(row['body_fat_mass_kg']),
    bodyWaterPercentage: _double(row['body_water_percentage']),
    bodyFatPercentage: _double(row['body_fat_percentage']),
    skeletalMuscleMassKg: _double(row['skeletal_muscle_mass_kg']),
    leanBodyMassKg: _double(row['lean_body_mass_kg']),
    fatFreeMassKg: _double(row['fat_free_mass_kg']),
    visceralFatLevel: _double(row['visceral_fat_level']),
    visceralFatAreaCm2: _double(row['visceral_fat_area_cm2']),
    subcutaneousFatPercentage: _double(row['subcutaneous_fat_percentage']),
    proteinPercentage: _double(row['protein_percentage']),
    mineralMassKg: _double(row['mineral_mass_kg']),
    boneMassKg: _double(row['bone_mass_kg']),
    bmi: _double(row['bmi']),
    basalMetabolicRateKcal: _double(row['basal_metabolic_rate_kcal']),
    metabolicAge: row['metabolic_age'] as int?,
    waistHipRatio: _double(row['waist_hip_ratio']),
    waistCircumferenceCm: _double(row['waist_circumference_cm']),
    hipCircumferenceCm: _double(row['hip_circumference_cm']),
    bodyCellMassKg: _double(row['body_cell_mass_kg']),
    intracellularWaterLiters: _double(row['intracellular_water_liters']),
    extracellularWaterLiters: _double(row['extracellular_water_liters']),
    totalBodyWaterLiters: _double(row['total_body_water_liters']),
    phaseAngleDegrees: _double(row['phase_angle_degrees']),
    bodyScore: _double(row['body_score']),
    recommendedWeightKg: _double(row['recommended_weight_kg']),
    weightControlKg: _double(row['weight_control_kg']),
    fatControlKg: _double(row['fat_control_kg']),
    muscleControlKg: _double(row['muscle_control_kg']),
    deviceName: row['device_name'] as String?,
    clinicName: row['clinic_name'] as String?,
    professionalName: row['professional_name'] as String?,
    notes: row['notes'] as String?,
    sourceDocumentId: row['source_document_id'] as String?,
    source: BioimpedanceRecordSource.values.firstWhere(
      (value) => value.name == row['source'],
      orElse: () => BioimpedanceRecordSource.manual,
    ),
    additionalMetrics: _metrics(row['additional_metrics']),
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: metadata.deletedAt,
    syncStatus: metadata.syncStatus,
  );

  static String metricsToJson(
    Map<String, BioimpedanceAdditionalMetric> value,
  ) => jsonEncode(_metricsJsonObject(value));

  static Map<String, BioimpedanceAdditionalMetric> metricsFromJson(
    String json,
  ) => _metrics(jsonDecode(json));

  static Map<String, dynamic> _metricsJsonObject(
    Map<String, BioimpedanceAdditionalMetric> value,
  ) => value.map((key, metric) => MapEntry(key, metric.toJson()));

  static Map<String, BioimpedanceAdditionalMetric> _metrics(Object? value) {
    if (value == null) return const {};
    final map = value is String
        ? jsonDecode(value) as Map<String, dynamic>
        : Map<String, dynamic>.from(value as Map);
    return map.map(
      (key, metric) => MapEntry(
        key,
        BioimpedanceAdditionalMetric.fromJson(
          Map<String, dynamic>.from(metric as Map),
        ),
      ),
    );
  }

  static double? _double(Object? value) => (value as num?)?.toDouble();
  static DateTime? _date(Object? value) => switch (value) {
    final DateTime date => date,
    final String text => DateTime.parse(text),
    _ => null,
  };

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) =>
      switch (currentStatus) {
        SyncStatus.synced => SyncStatus.pendingUpdate,
        SyncStatus.failed => SyncStatus.pendingUpdate,
        SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
        SyncStatus.pendingCreate => SyncStatus.pendingCreate,
        SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
        null => SyncStatus.pendingCreate,
      };
}

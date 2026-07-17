import '../../../../core/sync/sync.dart';

enum BioimpedanceRecordSource { manual, document }

enum BioimpedanceMetricSource { manual, document }

class BioimpedanceAdditionalMetric {
  const BioimpedanceAdditionalMetric({
    required this.key,
    required this.label,
    required this.originalValue,
    required this.source,
    this.numericValue,
    this.unit,
    this.section,
    this.confidence,
    this.sourceText,
  });

  final String key;
  final String label;
  final String originalValue;
  final double? numericValue;
  final String? unit;
  final String? section;
  final double? confidence;
  final String? sourceText;
  final BioimpedanceMetricSource source;

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'originalValue': originalValue,
    'numericValue': numericValue,
    'unit': unit,
    'section': section,
    'confidence': confidence,
    'sourceText': sourceText,
    'source': source.name,
  };

  factory BioimpedanceAdditionalMetric.fromJson(Map<String, dynamic> json) =>
      BioimpedanceAdditionalMetric(
        key: json['key'] as String,
        label: json['label'] as String,
        originalValue: json['originalValue'] as String,
        numericValue: (json['numericValue'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        section: json['section'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
        sourceText: json['sourceText'] as String?,
        source: BioimpedanceMetricSource.values.firstWhere(
          (value) => value.name == json['source'],
          orElse: () => BioimpedanceMetricSource.manual,
        ),
      );
}

class BioimpedanceRecord {
  const BioimpedanceRecord({
    required this.id,
    required this.userId,
    required this.measuredAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.weightKg,
    this.muscleMassKg,
    this.bodyFatMassKg,
    this.bodyWaterPercentage,
    this.bodyFatPercentage,
    this.skeletalMuscleMassKg,
    this.leanBodyMassKg,
    this.fatFreeMassKg,
    this.visceralFatLevel,
    this.visceralFatAreaCm2,
    this.subcutaneousFatPercentage,
    this.proteinPercentage,
    this.mineralMassKg,
    this.boneMassKg,
    this.bmi,
    this.basalMetabolicRateKcal,
    this.metabolicAge,
    this.waistHipRatio,
    this.waistCircumferenceCm,
    this.hipCircumferenceCm,
    this.bodyCellMassKg,
    this.intracellularWaterLiters,
    this.extracellularWaterLiters,
    this.totalBodyWaterLiters,
    this.phaseAngleDegrees,
    this.bodyScore,
    this.recommendedWeightKg,
    this.weightControlKg,
    this.fatControlKg,
    this.muscleControlKg,
    this.deviceName,
    this.clinicName,
    this.professionalName,
    this.notes,
    this.sourceDocumentId,
    this.additionalMetrics = const {},
    this.deletedAt,
  });

  final String id;
  final String userId;
  final DateTime measuredAt;
  final double? weightKg;
  final double? muscleMassKg;
  final double? bodyFatMassKg;
  final double? bodyWaterPercentage;
  final double? bodyFatPercentage;
  final double? skeletalMuscleMassKg;
  final double? leanBodyMassKg;
  final double? fatFreeMassKg;
  final double? visceralFatLevel;
  final double? visceralFatAreaCm2;
  final double? subcutaneousFatPercentage;
  final double? proteinPercentage;
  final double? mineralMassKg;
  final double? boneMassKg;
  final double? bmi;
  final double? basalMetabolicRateKcal;
  final int? metabolicAge;
  final double? waistHipRatio;
  final double? waistCircumferenceCm;
  final double? hipCircumferenceCm;
  final double? bodyCellMassKg;
  final double? intracellularWaterLiters;
  final double? extracellularWaterLiters;
  final double? totalBodyWaterLiters;
  final double? phaseAngleDegrees;
  final double? bodyScore;
  final double? recommendedWeightKg;
  final double? weightControlKg;
  final double? fatControlKg;
  final double? muscleControlKg;
  final String? deviceName;
  final String? clinicName;
  final String? professionalName;
  final String? notes;
  final String? sourceDocumentId;
  final BioimpedanceRecordSource source;
  final Map<String, BioimpedanceAdditionalMetric> additionalMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get hasAnyMeasurement =>
      weightKg != null ||
      muscleMassKg != null ||
      bodyFatMassKg != null ||
      bodyWaterPercentage != null ||
      bodyFatPercentage != null ||
      skeletalMuscleMassKg != null ||
      leanBodyMassKg != null ||
      fatFreeMassKg != null ||
      visceralFatLevel != null ||
      visceralFatAreaCm2 != null ||
      subcutaneousFatPercentage != null ||
      proteinPercentage != null ||
      mineralMassKg != null ||
      boneMassKg != null ||
      bmi != null ||
      basalMetabolicRateKcal != null ||
      metabolicAge != null ||
      waistHipRatio != null ||
      waistCircumferenceCm != null ||
      hipCircumferenceCm != null ||
      bodyCellMassKg != null ||
      intracellularWaterLiters != null ||
      extracellularWaterLiters != null ||
      totalBodyWaterLiters != null ||
      phaseAngleDegrees != null ||
      bodyScore != null ||
      recommendedWeightKg != null ||
      weightControlKg != null ||
      fatControlKg != null ||
      muscleControlKg != null ||
      additionalMetrics.isNotEmpty;

  BioimpedanceRecord copyWith({
    DateTime? measuredAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => BioimpedanceRecord(
    id: id,
    userId: userId,
    measuredAt: measuredAt ?? this.measuredAt,
    weightKg: weightKg,
    muscleMassKg: muscleMassKg,
    bodyFatMassKg: bodyFatMassKg,
    bodyWaterPercentage: bodyWaterPercentage,
    bodyFatPercentage: bodyFatPercentage,
    skeletalMuscleMassKg: skeletalMuscleMassKg,
    leanBodyMassKg: leanBodyMassKg,
    fatFreeMassKg: fatFreeMassKg,
    visceralFatLevel: visceralFatLevel,
    visceralFatAreaCm2: visceralFatAreaCm2,
    subcutaneousFatPercentage: subcutaneousFatPercentage,
    proteinPercentage: proteinPercentage,
    mineralMassKg: mineralMassKg,
    boneMassKg: boneMassKg,
    bmi: bmi,
    basalMetabolicRateKcal: basalMetabolicRateKcal,
    metabolicAge: metabolicAge,
    waistHipRatio: waistHipRatio,
    waistCircumferenceCm: waistCircumferenceCm,
    hipCircumferenceCm: hipCircumferenceCm,
    bodyCellMassKg: bodyCellMassKg,
    intracellularWaterLiters: intracellularWaterLiters,
    extracellularWaterLiters: extracellularWaterLiters,
    totalBodyWaterLiters: totalBodyWaterLiters,
    phaseAngleDegrees: phaseAngleDegrees,
    bodyScore: bodyScore,
    recommendedWeightKg: recommendedWeightKg,
    weightControlKg: weightControlKg,
    fatControlKg: fatControlKg,
    muscleControlKg: muscleControlKg,
    deviceName: deviceName,
    clinicName: clinicName,
    professionalName: professionalName,
    notes: notes,
    sourceDocumentId: sourceDocumentId,
    source: source,
    additionalMetrics: additionalMetrics,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

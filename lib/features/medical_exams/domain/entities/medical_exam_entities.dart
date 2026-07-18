import '../../../../core/sync/sync.dart';

enum MedicalExamSource {
  manual,
  document,
  imported,
  professionalPortal,
  unknown,
}

enum MedicalExamCategory {
  bloodCount,
  vitamins,
  minerals,
  metabolic,
  liver,
  kidney,
  thyroid,
  lipids,
  glucose,
  hormones,
  inflammation,
  coagulation,
  urine,
  stool,
  imaging,
  pathology,
  other,
}

enum MedicalExamValueType {
  numeric,
  text,
  qualitative,
  boolean,
  notDetected,
  detected,
  inconclusive,
  unknown,
}

enum MedicalExamResultSource { manual, document, normalizedCatalog, unknown }

enum ReferenceComparator {
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  between,
  equal,
  textual,
}

class MedicalExamResult {
  const MedicalExamResult({
    required this.id,
    required this.medicalExamId,
    required this.canonicalName,
    required this.displayName,
    required this.normalizedName,
    required this.valueType,
    required this.source,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.canonicalCode,
    this.category,
    this.numericValue,
    this.textValue,
    this.booleanValue,
    this.qualitativeValue,
    this.unit,
    this.normalizedUnit,
    this.referenceRangeText,
    this.referenceMin,
    this.referenceMax,
    this.referenceComparator,
    this.referenceContext,
    this.status,
    this.method,
    this.specimen,
    this.notes,
    this.originalText,
    this.confidence,
    this.deletedAt,
  });

  final String id;
  final String medicalExamId;
  final String? canonicalCode;
  final String canonicalName;
  final String displayName;
  final String normalizedName;
  final MedicalExamCategory? category;
  final MedicalExamValueType valueType;
  final double? numericValue;
  final String? textValue;
  final bool? booleanValue;
  final String? qualitativeValue;
  final String? unit;
  final String? normalizedUnit;
  final String? referenceRangeText;
  final double? referenceMin;
  final double? referenceMax;
  final ReferenceComparator? referenceComparator;
  final String? referenceContext;
  final String? status;
  final String? method;
  final String? specimen;
  final String? notes;
  final String? originalText;
  final MedicalExamResultSource source;
  final double? confidence;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get hasValue =>
      numericValue != null ||
      (textValue?.trim().isNotEmpty ?? false) ||
      booleanValue != null ||
      (qualitativeValue?.trim().isNotEmpty ?? false) ||
      valueType == MedicalExamValueType.notDetected ||
      valueType == MedicalExamValueType.detected ||
      valueType == MedicalExamValueType.inconclusive;

  bool get canGraph =>
      deletedAt == null &&
      valueType == MedicalExamValueType.numeric &&
      numericValue != null &&
      normalizedUnit != null &&
      normalizedUnit!.trim().isNotEmpty;

  MedicalExamResult copyWith({
    String? medicalExamId,
    String? canonicalCode,
    String? canonicalName,
    String? displayName,
    String? normalizedName,
    MedicalExamCategory? category,
    MedicalExamValueType? valueType,
    double? numericValue,
    String? textValue,
    bool? booleanValue,
    String? qualitativeValue,
    String? unit,
    String? normalizedUnit,
    String? referenceRangeText,
    double? referenceMin,
    double? referenceMax,
    ReferenceComparator? referenceComparator,
    String? referenceContext,
    String? status,
    String? method,
    String? specimen,
    String? notes,
    String? originalText,
    MedicalExamResultSource? source,
    double? confidence,
    int? sortOrder,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => MedicalExamResult(
    id: id,
    medicalExamId: medicalExamId ?? this.medicalExamId,
    canonicalCode: canonicalCode ?? this.canonicalCode,
    canonicalName: canonicalName ?? this.canonicalName,
    displayName: displayName ?? this.displayName,
    normalizedName: normalizedName ?? this.normalizedName,
    category: category ?? this.category,
    valueType: valueType ?? this.valueType,
    numericValue: numericValue ?? this.numericValue,
    textValue: textValue ?? this.textValue,
    booleanValue: booleanValue ?? this.booleanValue,
    qualitativeValue: qualitativeValue ?? this.qualitativeValue,
    unit: unit ?? this.unit,
    normalizedUnit: normalizedUnit ?? this.normalizedUnit,
    referenceRangeText: referenceRangeText ?? this.referenceRangeText,
    referenceMin: referenceMin ?? this.referenceMin,
    referenceMax: referenceMax ?? this.referenceMax,
    referenceComparator: referenceComparator ?? this.referenceComparator,
    referenceContext: referenceContext ?? this.referenceContext,
    status: status ?? this.status,
    method: method ?? this.method,
    specimen: specimen ?? this.specimen,
    notes: notes ?? this.notes,
    originalText: originalText ?? this.originalText,
    source: source ?? this.source,
    confidence: confidence ?? this.confidence,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

class MedicalExam {
  const MedicalExam({
    required this.id,
    required this.userId,
    required this.performedAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.collectedAt,
    this.receivedAt,
    this.title,
    this.examCategory,
    this.laboratoryName,
    this.professionalName,
    this.requestProfessionalName,
    this.documentNumber,
    this.notes,
    this.sourceDocumentId,
    this.legacyAttachmentPath,
    this.results = const <MedicalExamResult>[],
    this.deletedAt,
  });

  final String id;
  final String userId;
  final DateTime performedAt;
  final DateTime? collectedAt;
  final DateTime? receivedAt;
  final String? title;
  final MedicalExamCategory? examCategory;
  final String? laboratoryName;
  final String? professionalName;
  final String? requestProfessionalName;
  final String? documentNumber;
  final String? notes;
  final MedicalExamSource source;
  final String? sourceDocumentId;
  final String? legacyAttachmentPath;
  final List<MedicalExamResult> results;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  bool get hasAnyContent =>
      (title?.trim().isNotEmpty ?? false) ||
      results.any((item) => item.deletedAt == null && item.hasValue);

  bool get hasDocument =>
      sourceDocumentId != null && sourceDocumentId!.trim().isNotEmpty;

  bool get hasLegacyAttachment =>
      legacyAttachmentPath != null && legacyAttachmentPath!.trim().isNotEmpty;

  int get activeResultsCount =>
      results.where((item) => item.deletedAt == null).length;

  MedicalExam copyWith({
    DateTime? performedAt,
    DateTime? collectedAt,
    DateTime? receivedAt,
    String? title,
    MedicalExamCategory? examCategory,
    String? laboratoryName,
    String? professionalName,
    String? requestProfessionalName,
    String? documentNumber,
    String? notes,
    MedicalExamSource? source,
    String? sourceDocumentId,
    String? legacyAttachmentPath,
    List<MedicalExamResult>? results,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
  }) => MedicalExam(
    id: id,
    userId: userId,
    performedAt: performedAt ?? this.performedAt,
    collectedAt: collectedAt ?? this.collectedAt,
    receivedAt: receivedAt ?? this.receivedAt,
    title: title ?? this.title,
    examCategory: examCategory ?? this.examCategory,
    laboratoryName: laboratoryName ?? this.laboratoryName,
    professionalName: professionalName ?? this.professionalName,
    requestProfessionalName:
        requestProfessionalName ?? this.requestProfessionalName,
    documentNumber: documentNumber ?? this.documentNumber,
    notes: notes ?? this.notes,
    source: source ?? this.source,
    sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
    legacyAttachmentPath: legacyAttachmentPath ?? this.legacyAttachmentPath,
    results: results ?? this.results,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

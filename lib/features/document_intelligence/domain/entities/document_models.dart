enum DocumentSourceType { camera, gallery, file, pdf, existingAttachment }

enum ProcessingStatus {
  pending,
  processing,
  processed,
  requiresReview,
  confirmed,
  failed,
}

enum DetectedDocumentType {
  labResult,
  consultationNote,
  medicalReport,
  prescription,
  examRequest,
  unknown,
}

enum FieldStatus { extracted, uncertain, edited, confirmed, ignored }

enum FieldSource {
  ocr,
  importedText,
  manual,
  ocrEdited,
  futureProfessionalPortal,
}

enum ConfidenceLevel { low, medium, high }

extension ConfidenceValue on double {
  double get normalizedConfidence => clamp(0, 1).toDouble();
  ConfidenceLevel get confidenceLevel => switch (normalizedConfidence) {
    >= 0.8 => ConfidenceLevel.high,
    >= 0.5 => ConfidenceLevel.medium,
    _ => ConfidenceLevel.low,
  };
}

class DocumentInput {
  const DocumentInput({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.mimeType,
    required this.fileName,
    required this.fileSize,
    required this.capturedAt,
    required this.createdAt,
    this.localPath,
    this.remotePath,
    this.checksum,
  });

  final String id;
  final String userId;
  final DocumentSourceType sourceType;
  final String? localPath;
  final String? remotePath;
  final String mimeType;
  final String fileName;
  final int fileSize;
  final String? checksum;
  final DateTime capturedAt;
  final DateTime createdAt;
}

class DocumentProcessing {
  const DocumentProcessing({
    required this.id,
    required this.documentId,
    required this.status,
    required this.detectedType,
    required this.engine,
    required this.generalConfidence,
    required this.createdAt,
    required this.updatedAt,
    this.rawText,
    this.engineVersion,
    this.errorCode,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String documentId;
  final ProcessingStatus status;
  final DetectedDocumentType detectedType;
  final String? rawText;
  final String engine;
  final String? engineVersion;
  final double generalConfidence;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ExtractedField {
  const ExtractedField({
    required this.id,
    required this.processingId,
    required this.key,
    required this.label,
    required this.rawValue,
    required this.confidence,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.normalizedValue,
    this.confirmedValue,
    this.unit,
    this.originalBoundingBox,
  });

  final String id;
  final String processingId;
  final String key;
  final String label;
  final String rawValue;
  final String? normalizedValue;
  final String? confirmedValue;
  final String? unit;
  final double confidence;
  final FieldStatus status;
  final FieldSource source;
  final String? originalBoundingBox;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExtractedField copyWith({
    String? confirmedValue,
    double? confidence,
    FieldStatus? status,
    FieldSource? source,
    DateTime? updatedAt,
  }) => ExtractedField(
    id: id,
    processingId: processingId,
    key: key,
    label: label,
    rawValue: rawValue,
    normalizedValue: normalizedValue,
    confirmedValue: confirmedValue ?? this.confirmedValue,
    unit: unit,
    confidence: confidence ?? this.confidence,
    status: status ?? this.status,
    source: source ?? this.source,
    originalBoundingBox: originalBoundingBox,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class DocumentCandidateResult {
  const DocumentCandidateResult({
    required this.type,
    required this.confidence,
    required this.fields,
  });

  final DetectedDocumentType type;
  final double confidence;
  final List<ExtractedField> fields;
}

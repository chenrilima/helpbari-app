import '../data/datasources/ml_kit_document_text_extractor.dart';
import '../domain/entities/document_models.dart';
import '../domain/repositories/document_intelligence_contracts.dart';

class DocumentProcessingService {
  const DocumentProcessingService({
    required DocumentTextExtractor extractor,
    required DocumentClassifier classifier,
    required List<DocumentFieldParser> parsers,
  }) : _extractor = extractor,
       _classifier = classifier,
       _parsers = parsers;

  final DocumentTextExtractor _extractor;
  final DocumentClassifier _classifier;
  final List<DocumentFieldParser> _parsers;

  Future<({DocumentProcessing processing, List<ExtractedField> fields})>
  process({
    required DocumentInput document,
    required String processingId,
    required DateTime now,
  }) async {
    try {
      final path = document.localPath;
      if (path == null || path.isEmpty) {
        throw const DocumentExtractionException(
          code: 'original_file_missing',
          message: 'O arquivo original não está disponível.',
        );
      }
      final text = await _extractor.extract(
        path: path,
        mimeType: document.mimeType,
      );
      final classification = _classifier.classify(text);
      DocumentFieldParser? parser;
      for (final candidate in _parsers) {
        if (candidate.supportedTypes.contains(classification.type)) {
          parser = candidate;
          break;
        }
      }
      final fields =
          parser?.parse(processingId: processingId, text: text) ??
          const <ExtractedField>[];
      final requiresReview =
          classification.type == DetectedDocumentType.unknown ||
          classification.confidence < 0.8 ||
          fields.any((field) => field.confidence < 0.8);
      return (
        processing: DocumentProcessing(
          id: processingId,
          documentId: document.id,
          status: requiresReview
              ? ProcessingStatus.requiresReview
              : ProcessingStatus.processed,
          detectedType: classification.type,
          rawText: text,
          engine: _extractor.engine,
          generalConfidence: classification.confidence,
          startedAt: now,
          completedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        fields: fields,
      );
    } on DocumentExtractionException catch (error) {
      return (
        processing: DocumentProcessing(
          id: processingId,
          documentId: document.id,
          status: ProcessingStatus.failed,
          detectedType: DetectedDocumentType.unknown,
          engine: _extractor.engine,
          generalConfidence: 0,
          errorCode: error.code,
          errorMessage: error.message,
          startedAt: now,
          completedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        fields: const <ExtractedField>[],
      );
    }
  }
}

class DocumentReviewService {
  const DocumentReviewService();

  ExtractedField edit(ExtractedField field, String value, DateTime now) =>
      field.copyWith(
        confirmedValue: value.trim(),
        status: FieldStatus.edited,
        source: field.source == FieldSource.ocr
            ? FieldSource.ocrEdited
            : FieldSource.manual,
        updatedAt: now,
      );

  List<ExtractedField> confirm(List<ExtractedField> fields, DateTime now) {
    return fields
        .map((field) {
          if (field.status == FieldStatus.ignored) return field;
          return field.copyWith(
            confirmedValue:
                field.confirmedValue ?? field.normalizedValue ?? field.rawValue,
            status: FieldStatus.confirmed,
            updatedAt: now,
          );
        })
        .toList(growable: false);
  }
}

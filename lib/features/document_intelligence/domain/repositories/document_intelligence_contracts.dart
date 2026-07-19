import 'dart:typed_data';

import '../entities/document_models.dart';

abstract interface class DocumentTextExtractor {
  String get engine;
  bool supportsMimeType(String mimeType);
  Future<String> extract({required String path, required String mimeType});
}

abstract interface class DocumentClassifier {
  DocumentCandidateResult classify(String text);
}

abstract interface class DocumentFieldParser {
  Set<DetectedDocumentType> get supportedTypes;
  List<ExtractedField> parse({
    required String processingId,
    required String text,
  });
}

abstract interface class DocumentStorageGateway {
  Future<String> upload({
    required String userId,
    required String documentId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
  Future<Uint8List> download(String remotePath);
  Future<void> remove(String remotePath);
}

abstract interface class DocumentProcessingRepository {
  Stream<List<ManagedDocumentRecord>> watchDocuments(String userId);
  Future<List<ManagedDocumentRecord>> getDocuments(String userId);
  Future<ManagedDocumentRecord?> getDocumentById(
    String userId,
    String documentId,
  );
  Future<List<ManagedDocumentRecord>> searchDocuments(
    String userId, {
    required String query,
  });
  Stream<List<ManagedDocumentRecord>> watchOrphanDocuments(String userId);
  Future<void> saveDocument(DocumentInput document);
  Future<void> updateDocumentRemotePath({
    required String userId,
    required String documentId,
    required String remotePath,
    required DateTime updatedAt,
  });
  Future<void> saveProcessing(String userId, DocumentProcessing processing);
  Future<void> replaceFields(
    String userId,
    String processingId,
    List<ExtractedField> fields,
  );
  Future<DocumentProcessing?> getProcessing(String userId, String processingId);
  Future<List<ExtractedField>> getFields(String userId, String processingId);
  Future<void> deleteDocument(String userId, String documentId, DateTime at);
}

abstract interface class DocumentReviewRepository {
  Future<void> saveReview({
    required DocumentProcessing processing,
    required List<ExtractedField> fields,
  });
}

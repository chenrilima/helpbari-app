import '../../../../core/sync/sync.dart';

class DocumentProcessingSyncDto {
  const DocumentProcessingSyncDto({
    required this.id,
    required this.userId,
    required this.documentId,
    required this.document,
    required this.processing,
    required this.fields,
    required this.syncMetadata,
  });

  final String id;
  final String userId;
  final String documentId;
  final Map<String, dynamic> document;
  final Map<String, dynamic> processing;
  final List<Map<String, dynamic>> fields;
  final SyncMetadata syncMetadata;

  Map<String, dynamic> toProcessingRow() => {
    'id': id,
    'user_id': userId,
    'document_id': documentId,
    ...processing,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toDocumentRow() => {
    'id': documentId,
    'user_id': userId,
    ...document,
  };

  List<Map<String, dynamic>> toFieldRows() => fields
      .map((field) => {'user_id': userId, 'processing_id': id, ...field})
      .toList(growable: false);

  static DocumentProcessingSyncDto fromSupabase({
    required Map<String, dynamic> processing,
    required Map<String, dynamic> document,
    required List<Map<String, dynamic>> fields,
  }) {
    final id = processing['id'] as String;
    final userId = processing['user_id'] as String;
    final documentId = processing['document_id'] as String;
    return DocumentProcessingSyncDto(
      id: id,
      userId: userId,
      documentId: documentId,
      document: {
        'source_type': document['source_type'],
        'remote_path': document['remote_path'],
        'mime_type': document['mime_type'],
        'file_name': document['file_name'],
        'file_size': document['file_size'],
        'checksum': document['checksum'],
        'captured_at': document['captured_at'],
        'created_at': document['created_at'],
        'updated_at': document['updated_at'],
        'deleted_at': document['deleted_at'],
      },
      processing: {
        'status': processing['status'],
        'detected_type': processing['detected_type'],
        'raw_text': processing['raw_text'],
        'engine': processing['engine'],
        'engine_version': processing['engine_version'],
        'general_confidence': processing['general_confidence'],
        'error_code': processing['error_code'],
        'error_message': processing['error_message'],
        'started_at': processing['started_at'],
        'completed_at': processing['completed_at'],
      },
      fields: fields,
      syncMetadata: SyncMetadata(
        id: id,
        userId: userId,
        createdAt: DateTime.parse(processing['created_at'] as String),
        updatedAt: DateTime.parse(processing['updated_at'] as String),
        deletedAt: switch (processing['deleted_at']) {
          final String value when value.isNotEmpty => DateTime.parse(value),
          _ => null,
        },
        syncStatus: SyncStatus.synced,
        serverRevision: processing['server_revision'] as int?,
      ),
    );
  }
}

import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/document_intelligence_dao.dart';
import '../../../../core/sync/sync.dart';
import '../datasources/document_processing_supabase_datasource.dart';
import '../dtos/document_processing_sync_dto.dart';

class DocumentProcessingSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const DocumentProcessingSyncRepository({
    required Future<DocumentIntelligenceDao> Function() local,
    required DocumentProcessingSupabaseDatasource remote,
    required String userId,
  }) : _local = local,
       _remote = remote,
       _userId = userId;

  static const key = 'document_processings';
  final Future<DocumentIntelligenceDao> Function() _local;
  final DocumentProcessingSupabaseDatasource _remote;
  final String _userId;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    final dao = await _local();
    final rows = await dao.getPendingProcessings(_userId);
    final operations = <SyncOperation>[];
    for (final row in rows) {
      final dto = await _dtoFromLocal(dao, row);
      if (dto != null) operations.add(_op(dto, row.syncStatus));
    }
    return operations;
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final dao = await _local();
    final row = await dao.getAnyProcessing(_userId, recordId);
    if (row == null || row.syncStatus == SyncStatus.synced.name) return null;
    final dto = await _dtoFromLocal(dao, row);
    return dto == null ? null : _op(dto, row.syncStatus);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final remote = await _remote.upsert(_dto(operation), userId: _userId);
    await _applyRemote(remote, markSynced: true);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map((dto) => _op(dto, SyncStatus.synced.name)).toList();

  @override
  Future<void> applyRemote(SyncOperation operation) =>
      _applyRemote(_dto(operation), markSynced: false);

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) => _applyRemote(_dto(operation), markSynced: true, syncedAt: syncedAt);

  @override
  Future<void> markSynced(
    String recordId, {
    required DateTime syncedAt,
  }) async =>
      (await _local()).markProcessingSynced(_userId, recordId, syncedAt);

  @override
  Future<void> markFailed(String recordId, SyncError error) async =>
      (await _local()).markProcessingFailed(_userId, recordId, error.message);

  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _local()).getLastPullAt(_userId, key);

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async =>
      (await _local()).saveCursor(_userId, key, completedAt);

  Future<DocumentProcessingSyncDto?> _dtoFromLocal(
    DocumentIntelligenceDao dao,
    DocumentProcessingRecord processing,
  ) async {
    final document = await dao.getDocument(_userId, processing.documentId);
    if (document == null) return null;
    final fields = await dao.getFields(_userId, processing.id);
    return DocumentProcessingSyncDto(
      id: processing.id,
      userId: _userId,
      documentId: processing.documentId,
      document: {
        'source_type': document.sourceType,
        'remote_path': document.remotePath,
        'mime_type': document.mimeType,
        'file_name': document.fileName,
        'file_size': document.fileSize,
        'checksum': document.checksum,
        'captured_at': document.capturedAt.toUtc().toIso8601String(),
        'created_at': document.createdAt.toUtc().toIso8601String(),
        'updated_at': document.updatedAt.toUtc().toIso8601String(),
        'deleted_at': document.deletedAt?.toUtc().toIso8601String(),
      },
      processing: {
        'status': processing.status,
        'detected_type': processing.detectedType,
        'raw_text': processing.rawText,
        'engine': processing.engine,
        'engine_version': processing.engineVersion,
        'general_confidence': processing.generalConfidence,
        'error_code': processing.errorCode,
        'error_message': processing.errorMessage,
        'started_at': processing.startedAt?.toUtc().toIso8601String(),
        'completed_at': processing.completedAt?.toUtc().toIso8601String(),
      },
      fields: fields
          .map(
            (field) => {
              'id': field.id,
              'key': field.key,
              'label': field.label,
              'raw_value': field.rawValue,
              'normalized_value': field.normalizedValue,
              'confirmed_value': field.confirmedValue,
              'unit': field.unit,
              'confidence': field.confidence,
              'status': field.status,
              'source': field.source,
              'original_bounding_box': field.originalBoundingBox,
              'created_at': field.createdAt.toUtc().toIso8601String(),
              'updated_at': field.updatedAt.toUtc().toIso8601String(),
              'deleted_at': field.deletedAt?.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
      syncMetadata: SyncMetadata(
        id: processing.id,
        userId: _userId,
        createdAt: processing.createdAt,
        updatedAt: processing.updatedAt,
        deletedAt: processing.deletedAt,
        syncStatus: SyncStatus.fromName(processing.syncStatus),
      ),
    );
  }

  SyncOperation _op(DocumentProcessingSyncDto dto, String status) =>
      SyncOperation(
        repositoryKey: key,
        recordId: dto.id,
        type: dto.syncMetadata.isDeleted
            ? SyncOperationType.delete
            : const SyncStatusMapper().operationTypeFromStatus(
                SyncStatus.fromName(status),
              ),
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: dto.syncMetadata.deletedAt,
        userId: dto.userId,
        payload: {
          'documentId': dto.documentId,
          'document': dto.document,
          'processing': dto.processing,
          'fields': dto.fields,
          'createdAt': dto.syncMetadata.createdAt.toUtc().toIso8601String(),
        },
      );

  DocumentProcessingSyncDto _dto(SyncOperation operation) =>
      DocumentProcessingSyncDto(
        id: operation.recordId,
        userId: operation.userId ?? _userId,
        documentId: operation.payload['documentId'] as String,
        document: Map<String, dynamic>.from(
          operation.payload['document'] as Map,
        ),
        processing: Map<String, dynamic>.from(
          operation.payload['processing'] as Map,
        ),
        fields: (operation.payload['fields'] as List? ?? const [])
            .map((field) => Map<String, dynamic>.from(field as Map))
            .toList(growable: false),
        syncMetadata: SyncMetadata(
          id: operation.recordId,
          userId: operation.userId ?? _userId,
          createdAt: DateTime.parse(operation.payload['createdAt'] as String),
          updatedAt: operation.updatedAt,
          deletedAt: operation.deletedAt,
          syncStatus: operation.syncStatus,
        ),
      );

  Future<void> _applyRemote(
    DocumentProcessingSyncDto dto, {
    required bool markSynced,
    DateTime? syncedAt,
  }) async {
    if (dto.userId != _userId) return;
    final dao = await _local();
    final document = dto.document;
    final processing = dto.processing;
    await dao.inTransaction(() async {
      await dao.upsertDocument(
        DocumentInputRecordsCompanion.insert(
          id: dto.documentId,
          userId: _userId,
          sourceType: document['source_type'] as String,
          localPath: const Value.absent(),
          remotePath: Value(document['remote_path'] as String?),
          mimeType: document['mime_type'] as String,
          fileName: document['file_name'] as String,
          fileSize: document['file_size'] as int,
          checksum: Value(document['checksum'] as String?),
          capturedAt: DateTime.parse(document['captured_at'] as String),
          createdAt: DateTime.parse(document['created_at'] as String),
          updatedAt: DateTime.parse(document['updated_at'] as String),
          deletedAt: Value(_nullableDate(document['deleted_at'])),
          syncStatus: markSynced
              ? SyncStatus.synced.name
              : dto.syncMetadata.syncStatus.name,
        ),
      );
      await dao.upsertProcessing(
        DocumentProcessingRecordsCompanion.insert(
          id: dto.id,
          userId: _userId,
          documentId: dto.documentId,
          status: processing['status'] as String,
          detectedType: processing['detected_type'] as String,
          rawText: Value(processing['raw_text'] as String?),
          engine: processing['engine'] as String,
          engineVersion: Value(processing['engine_version'] as String?),
          generalConfidence: (processing['general_confidence'] as num)
              .toDouble(),
          errorCode: Value(processing['error_code'] as String?),
          errorMessage: Value(processing['error_message'] as String?),
          startedAt: Value(_nullableDate(processing['started_at'])),
          completedAt: Value(_nullableDate(processing['completed_at'])),
          createdAt: dto.syncMetadata.createdAt,
          updatedAt: dto.syncMetadata.updatedAt,
          deletedAt: Value(dto.syncMetadata.deletedAt),
          syncStatus: markSynced
              ? SyncStatus.synced.name
              : dto.syncMetadata.syncStatus.name,
        ),
      );
      await dao.replaceFields(
        _userId,
        dto.id,
        dto.fields
            .map(
              (field) => ExtractedFieldRecordsCompanion.insert(
                id: field['id'] as String,
                userId: _userId,
                processingId: dto.id,
                key: field['key'] as String,
                label: field['label'] as String,
                rawValue: field['raw_value'] as String,
                normalizedValue: Value(field['normalized_value'] as String?),
                confirmedValue: Value(field['confirmed_value'] as String?),
                unit: Value(field['unit'] as String?),
                confidence: (field['confidence'] as num).toDouble(),
                status: field['status'] as String,
                source: field['source'] as String,
                originalBoundingBox: Value(
                  field['original_bounding_box'] as String?,
                ),
                createdAt: DateTime.parse(field['created_at'] as String),
                updatedAt: DateTime.parse(field['updated_at'] as String),
                deletedAt: Value(_nullableDate(field['deleted_at'])),
                syncStatus: markSynced
                    ? SyncStatus.synced.name
                    : dto.syncMetadata.syncStatus.name,
              ),
            )
            .toList(growable: false),
      );
    });
  }

  DateTime? _nullableDate(Object? value) => switch (value) {
    final DateTime date => date,
    final String text when text.isNotEmpty => DateTime.parse(text),
    _ => null,
  };
}

import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/document_processing_sync_dto.dart';

class DocumentProcessingSupabaseDatasource {
  const DocumentProcessingSupabaseDatasource(this._database);
  final SupabaseDatabase _database;

  Future<DocumentProcessingSyncDto> upsert(
    DocumentProcessingSyncDto value, {
    required String userId,
  }) async {
    await _database.run(
      operation: 'upsert',
      table: 'document_inputs',
      request: (q) => q.upsert(value.toDocumentRow()),
    );
    final processing = await _database.run(
      operation: 'upsert',
      table: 'document_processings',
      request: (q) async => Map<String, dynamic>.from(
        await q.upsert(value.toProcessingRow()).select().single(),
      ),
    );
    final fields = value.toFieldRows();
    if (fields.isNotEmpty) {
      await _database.run(
        operation: 'upsert',
        table: 'extracted_document_fields',
        request: (q) => q.upsert(fields),
      );
    }
    return DocumentProcessingSyncDto.fromSupabase(
      processing: processing,
      document: value.toDocumentRow(),
      fields: fields,
    );
  }

  Future<List<DocumentProcessingSyncDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: 'document_processings',
    request: (q) async {
      var request = q.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      final processingRows = (await request.order(
        'updated_at',
      )).map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
      final results = <DocumentProcessingSyncDto>[];
      for (final processing in processingRows) {
        final documentId = processing['document_id'] as String;
        final processingId = processing['id'] as String;
        final document = await _database.run(
          operation: 'select',
          table: 'document_inputs',
          request: (query) async => Map<String, dynamic>.from(
            await query
                .select()
                .eq('user_id', userId)
                .eq('id', documentId)
                .single(),
          ),
        );
        final fields = await _database.run(
          operation: 'select',
          table: 'extracted_document_fields',
          request: (query) async =>
              (await query
                      .select()
                      .eq('user_id', userId)
                      .eq('processing_id', processingId)
                      .order('created_at'))
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false),
        );
        results.add(
          DocumentProcessingSyncDto.fromSupabase(
            processing: processing,
            document: document,
            fields: fields,
          ),
        );
      }
      return results;
    },
  );
}

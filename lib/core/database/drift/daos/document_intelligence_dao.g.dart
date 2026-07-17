// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_intelligence_dao.dart';

// ignore_for_file: type=lint
mixin _$DocumentIntelligenceDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentInputRecordsTable get documentInputRecords =>
      attachedDatabase.documentInputRecords;
  $DocumentProcessingRecordsTable get documentProcessingRecords =>
      attachedDatabase.documentProcessingRecords;
  $ExtractedFieldRecordsTable get extractedFieldRecords =>
      attachedDatabase.extractedFieldRecords;
  DocumentIntelligenceDaoManager get managers =>
      DocumentIntelligenceDaoManager(this);
}

class DocumentIntelligenceDaoManager {
  final _$DocumentIntelligenceDaoMixin _db;
  DocumentIntelligenceDaoManager(this._db);
  $$DocumentInputRecordsTableTableManager get documentInputRecords =>
      $$DocumentInputRecordsTableTableManager(
        _db.attachedDatabase,
        _db.documentInputRecords,
      );
  $$DocumentProcessingRecordsTableTableManager get documentProcessingRecords =>
      $$DocumentProcessingRecordsTableTableManager(
        _db.attachedDatabase,
        _db.documentProcessingRecords,
      );
  $$ExtractedFieldRecordsTableTableManager get extractedFieldRecords =>
      $$ExtractedFieldRecordsTableTableManager(
        _db.attachedDatabase,
        _db.extractedFieldRecords,
      );
}

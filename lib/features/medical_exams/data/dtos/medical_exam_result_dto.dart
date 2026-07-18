import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';

class MedicalExamResultDto {
  const MedicalExamResultDto({
    required this.result,
    required this.syncMetadata,
  });

  final MedicalExamResult result;
  final SyncMetadata syncMetadata;

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': result.id,
    'user_id': userId,
    'medical_exam_id': result.medicalExamId,
    'canonical_code': result.canonicalCode,
    'canonical_name': result.canonicalName,
    'display_name': result.displayName,
    'normalized_name': result.normalizedName,
    'category': result.category?.name,
    'value_type': result.valueType.name,
    'numeric_value': result.numericValue,
    'text_value': result.textValue,
    'boolean_value': result.booleanValue,
    'qualitative_value': result.qualitativeValue,
    'unit': result.unit,
    'normalized_unit': result.normalizedUnit,
    'reference_range_text': result.referenceRangeText,
    'reference_min': result.referenceMin,
    'reference_max': result.referenceMax,
    'reference_comparator': result.referenceComparator?.name,
    'reference_context': result.referenceContext,
    'status': result.status,
    'method': result.method,
    'specimen': result.specimen,
    'notes': result.notes,
    'original_text': result.originalText,
    'source': result.source.name,
    'confidence': result.confidence,
    'sort_order': result.sortOrder,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  factory MedicalExamResultDto.fromEntity(
    MedicalExamResult result, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return MedicalExamResultDto(
      result: result,
      syncMetadata: SyncMetadata(
        id: result.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? result.createdAt,
        updatedAt: now,
        deletedAt: result.deletedAt,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  factory MedicalExamResultDto.fromSupabaseRow(Map<String, dynamic> row) {
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
    return MedicalExamResultDto(
      result: _result(row, metadata),
      syncMetadata: metadata,
    );
  }

  static MedicalExamResult fromRowLike(Map<String, dynamic> row) {
    final metadata = SyncMetadata(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: _date(row['created_at'])!,
      updatedAt: _date(row['updated_at'])!,
      deletedAt: _date(row['deleted_at']),
      syncStatus: SyncStatus.fromName(row['sync_status'] as String?),
    );
    return _result(row, metadata);
  }

  static MedicalExamResult _result(
    Map<String, dynamic> row,
    SyncMetadata metadata,
  ) => MedicalExamResult(
    id: row['id'] as String,
    medicalExamId: row['medical_exam_id'] as String,
    canonicalCode: row['canonical_code'] as String?,
    canonicalName: row['canonical_name'] as String,
    displayName: row['display_name'] as String,
    normalizedName: row['normalized_name'] as String,
    category: _category(row['category'] as String?),
    valueType: MedicalExamValueType.values.firstWhere(
      (value) => value.name == row['value_type'],
      orElse: () => MedicalExamValueType.unknown,
    ),
    numericValue: _double(row['numeric_value']),
    textValue: row['text_value'] as String?,
    booleanValue: row['boolean_value'] as bool?,
    qualitativeValue: row['qualitative_value'] as String?,
    unit: row['unit'] as String?,
    normalizedUnit: row['normalized_unit'] as String?,
    referenceRangeText: row['reference_range_text'] as String?,
    referenceMin: _double(row['reference_min']),
    referenceMax: _double(row['reference_max']),
    referenceComparator: _referenceComparator(
      row['reference_comparator'] as String?,
    ),
    referenceContext: row['reference_context'] as String?,
    status: row['status'] as String?,
    method: row['method'] as String?,
    specimen: row['specimen'] as String?,
    notes: row['notes'] as String?,
    originalText: row['original_text'] as String?,
    source: MedicalExamResultSource.values.firstWhere(
      (value) => value.name == row['source'],
      orElse: () => MedicalExamResultSource.unknown,
    ),
    confidence: _double(row['confidence']),
    sortOrder: row['sort_order'] as int? ?? 0,
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: metadata.deletedAt,
    syncStatus: metadata.syncStatus,
  );

  static MedicalExamCategory? _category(String? value) => value == null
      ? null
      : MedicalExamCategory.values.firstWhere(
          (item) => item.name == value,
          orElse: () => MedicalExamCategory.other,
        );

  static ReferenceComparator? _referenceComparator(String? value) =>
      value == null
      ? null
      : ReferenceComparator.values.firstWhere(
          (item) => item.name == value,
          orElse: () => ReferenceComparator.textual,
        );

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

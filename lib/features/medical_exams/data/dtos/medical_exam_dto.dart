import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import 'medical_exam_result_dto.dart';

class MedicalExamDto {
  const MedicalExamDto({
    required this.exam,
    required this.results,
    required this.syncMetadata,
  });

  final MedicalExam exam;
  final List<MedicalExamResultDto> results;
  final SyncMetadata syncMetadata;

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': exam.id,
    'user_id': userId,
    'performed_at': exam.performedAt.toUtc().toIso8601String(),
    'collected_at': exam.collectedAt?.toUtc().toIso8601String(),
    'received_at': exam.receivedAt?.toUtc().toIso8601String(),
    'title': exam.title,
    'category': exam.examCategory?.name,
    'laboratory_name': exam.laboratoryName,
    'professional_name': exam.professionalName,
    'request_professional_name': exam.requestProfessionalName,
    'document_number': exam.documentNumber,
    'notes': exam.notes,
    'source': exam.source.name,
    'source_document_id': exam.sourceDocumentId,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  factory MedicalExamDto.fromEntity(
    MedicalExam exam, {
    required DateTime now,
    SyncMetadata? previousMetadata,
    Map<String, SyncMetadata> previousResultMetadata = const {},
  }) {
    final metadata = SyncMetadata(
      id: exam.id,
      userId: exam.userId,
      createdAt: previousMetadata?.createdAt ?? exam.createdAt,
      updatedAt: now,
      deletedAt: exam.deletedAt,
      syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
    );
    return MedicalExamDto(
      exam: exam,
      results: exam.results
          .map(
            (item) => MedicalExamResultDto.fromEntity(
              item,
              now: now,
              previousMetadata: previousResultMetadata[item.id],
            ),
          )
          .toList(growable: false),
      syncMetadata: metadata,
    );
  }

  factory MedicalExamDto.fromSupabaseRow({
    required Map<String, dynamic> exam,
    required List<Map<String, dynamic>> results,
  }) {
    final metadata = SyncMetadata(
      id: exam['id'] as String,
      userId: exam['user_id'] as String,
      createdAt: DateTime.parse(exam['created_at'] as String),
      updatedAt: DateTime.parse(exam['updated_at'] as String),
      deletedAt: exam['deleted_at'] == null
          ? null
          : DateTime.parse(exam['deleted_at'] as String),
      syncStatus: SyncStatus.synced,
    );
    final resultDtos = results
        .map(MedicalExamResultDto.fromSupabaseRow)
        .toList(growable: false);
    return MedicalExamDto(
      exam: _exam(
        exam,
        metadata,
        resultDtos.map((item) => item.result).toList(),
      ),
      results: resultDtos,
      syncMetadata: metadata,
    );
  }

  static MedicalExam _exam(
    Map<String, dynamic> row,
    SyncMetadata metadata,
    List<MedicalExamResult> results,
  ) => MedicalExam(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    performedAt: _date(row['performed_at'])!,
    collectedAt: _date(row['collected_at']),
    receivedAt: _date(row['received_at']),
    title: row['title'] as String?,
    examCategory: row['category'] == null
        ? null
        : MedicalExamCategory.values.firstWhere(
            (item) => item.name == row['category'],
            orElse: () => MedicalExamCategory.other,
          ),
    laboratoryName: row['laboratory_name'] as String?,
    professionalName: row['professional_name'] as String?,
    requestProfessionalName: row['request_professional_name'] as String?,
    documentNumber: row['document_number'] as String?,
    notes: row['notes'] as String?,
    source: MedicalExamSource.values.firstWhere(
      (item) => item.name == row['source'],
      orElse: () => MedicalExamSource.unknown,
    ),
    sourceDocumentId: row['source_document_id'] as String?,
    results: results,
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: metadata.deletedAt,
    syncStatus: metadata.syncStatus,
  );

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

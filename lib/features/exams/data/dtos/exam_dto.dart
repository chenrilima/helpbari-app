import '../../../../core/database/database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class ExamDto {
  const ExamDto({
    required this.id,
    required this.name,
    required this.examDate,
    required this.syncMetadata,
    this.laboratory,
    this.notes,
    this.attachmentPath,
  });

  final String id;
  final String name;
  final DateTime examDate;
  final String? laboratory;
  final String? notes;
  final String? attachmentPath;
  final SyncMetadata syncMetadata;

  Exam toEntity() {
    final examName = ExamName.create(name);

    if (examName == null) {
      throw FormatException('Exame local inválido: $id');
    }

    return Exam(
      id: id,
      name: examName,
      examDate: ExamDate(examDate),
      laboratory: laboratory,
      notes: notes,
      attachmentPath: attachmentPath,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'examDate': examDate.toIso8601String(),
        'laboratory': laboratory,
        'notes': notes,
        'attachmentPath': attachmentPath,
      },
    );
  }

  static ExamDto fromEntity(
    Exam exam, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return ExamDto(
      id: exam.id,
      name: exam.name.value,
      examDate: exam.examDate.value,
      laboratory: exam.laboratory,
      notes: exam.notes,
      attachmentPath: exam.attachmentPath,
      syncMetadata: SyncMetadata(
        id: exam.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static ExamDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return ExamDto(
      id: record.id,
      name: data['name'] as String,
      examDate: DateTime.parse(data['examDate'] as String),
      laboratory: data['laboratory'] as String?,
      notes: data['notes'] as String?,
      attachmentPath: data['attachmentPath'] as String?,
      syncMetadata: record.metadata,
    );
  }

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': id,
    'user_id': userId,
    'name': name,
    'exam_date': examDate.toUtc().toIso8601String(),
    'laboratory': laboratory,
    'notes': notes,
    'attachment_path': attachmentPath,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };
  factory ExamDto.fromSupabaseRow(Map<String, dynamic> row) => ExamDto(
    id: row['id'] as String,
    name: row['name'] as String,
    examDate: DateTime.parse(row['exam_date'] as String),
    laboratory: row['laboratory'] as String?,
    notes: row['notes'] as String?,
    attachmentPath: row['attachment_path'] as String?,
    syncMetadata: SyncMetadata(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String),
        syncStatus: SyncStatus.synced,
        serverRevision: row['server_revision'] as int?,
    ),
  );

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) {
    return switch (currentStatus) {
      SyncStatus.synced => SyncStatus.pendingUpdate,
      SyncStatus.failed => SyncStatus.pendingUpdate,
      SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
      SyncStatus.pendingCreate => SyncStatus.pendingCreate,
      SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
      null => SyncStatus.pendingCreate,
    };
  }
}

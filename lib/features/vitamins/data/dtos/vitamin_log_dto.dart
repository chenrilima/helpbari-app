import '../../../../core/sync/sync.dart';
import '../../domain/entities/vitamin_log.dart';
import '../../domain/value_objects/vitamin_status.dart';

class VitaminLogDto {
  const VitaminLogDto({
    required this.id,
    required this.vitaminId,
    required this.date,
    required this.status,
    required this.syncMetadata,
  });
  final String id;
  final String vitaminId;
  final DateTime date;
  final VitaminStatus status;
  final SyncMetadata syncMetadata;

  VitaminLog toEntity() =>
      VitaminLog(id: id, vitaminId: vitaminId, date: date, status: status);
  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': id,
    'user_id': userId,
    'vitamin_id': vitaminId,
    'log_date': _date(date),
    'status': status.name,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };
  factory VitaminLogDto.fromSupabaseRow(Map<String, dynamic> row) =>
      VitaminLogDto(
        id: row['id'] as String,
        vitaminId: row['vitamin_id'] as String,
        date: DateTime.parse(row['log_date'] as String),
        status: VitaminStatus.values.firstWhere(
          (value) => value.name == row['status'],
          orElse: () => VitaminStatus.pending,
        ),
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
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

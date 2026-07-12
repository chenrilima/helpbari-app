import '../../../../core/sync/sync.dart';
import '../../domain/entities/medication_log.dart';
import '../../domain/value_objects/medication_status.dart';

class MedicationLogDto {
  const MedicationLogDto({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.status,
    required this.syncMetadata,
  });
  final String id;
  final String medicationId;
  final DateTime date;
  final MedicationStatus status;
  final SyncMetadata syncMetadata;
  MedicationLog toEntity() => MedicationLog(
    id: id,
    medicationId: medicationId,
    date: date,
    status: status,
  );
  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': id,
    'user_id': userId,
    'medication_id': medicationId,
    'log_date': _date(date),
    'status': status.name,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };
  factory MedicationLogDto.fromSupabaseRow(Map<String, dynamic> row) =>
      MedicationLogDto(
        id: row['id'] as String,
        medicationId: row['medication_id'] as String,
        date: DateTime.parse(row['log_date'] as String),
        status: MedicationStatus.values.firstWhere(
          (v) => v.name == row['status'],
          orElse: () => MedicationStatus.pending,
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
        ),
      );
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

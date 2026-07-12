import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/medication_log_dto.dart';

class MedicationLogSupabaseDatasource {
  const MedicationLogSupabaseDatasource(this._database);
  final SupabaseDatabase _database;
  Future<MedicationLogDto> upsert(
    MedicationLogDto value, {
    required String userId,
  }) => _database.run(
    operation: 'upsert',
    table: 'medication_logs',
    request: (q) async => MedicationLogDto.fromSupabaseRow(
      Map<String, dynamic>.from(
        await q.upsert(value.toSupabaseRow(userId: userId)).select().single(),
      ),
    ),
  );
  Future<List<MedicationLogDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: 'medication_logs',
    request: (q) async {
      var request = q.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      return (await request.order(
        'updated_at',
      )).map(MedicationLogDto.fromSupabaseRow).toList();
    },
  );
}

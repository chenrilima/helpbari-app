import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/bioimpedance_record_dto.dart';

class BioimpedanceSupabaseDatasource {
  const BioimpedanceSupabaseDatasource(this._database);
  static const table = 'bioimpedance_records';
  final SupabaseDatabase _database;

  Future<BioimpedanceRecordDto> upsert(
    BioimpedanceRecordDto record, {
    required String userId,
  }) => _database.run(
    operation: 'upsert',
    table: table,
    request: (query) async => BioimpedanceRecordDto.fromSupabaseRow(
      Map<String, dynamic>.from(
        await query
            .upsert(record.toSupabaseRow(userId: userId))
            .select()
            .single(),
      ),
    ),
  );

  Future<List<BioimpedanceRecordDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: table,
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      final rows = await request.order('updated_at');
      return rows.map(BioimpedanceRecordDto.fromSupabaseRow).toList();
    },
  );
}

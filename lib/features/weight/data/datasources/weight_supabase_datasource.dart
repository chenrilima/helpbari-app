import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/weight_record_dto.dart';

class WeightSupabaseDatasource {
  const WeightSupabaseDatasource(this._database);
  static const table = 'weight_records';
  final SupabaseDatabase _database;

  Future<WeightRecordDto> upsert(
    WeightRecordDto record, {
    required String userId,
  }) => _database.run(
    operation: 'upsert',
    table: table,
    request: (query) async => WeightRecordDto.fromSupabaseRow(
      Map<String, dynamic>.from(
        await query
            .upsert(record.toSupabaseInsert(userId: userId))
            .select()
            .single(),
      ),
    ),
  );

  Future<List<WeightRecordDto>> pull({
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
      return rows.map(WeightRecordDto.fromSupabaseRow).toList();
    },
  );
}

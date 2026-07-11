import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/water_record_dto.dart';

class WaterSupabaseDatasource {
  const WaterSupabaseDatasource(this._database);

  static const table = 'water_records';

  final SupabaseDatabase _database;

  Future<WaterRecordDto> insert(
    WaterRecordDto record, {
    required String userId,
  }) {
    return _database.run(
      operation: 'insert',
      table: table,
      request: (query) async {
        final response = await query
            .upsert(record.toSupabaseInsert(userId: userId))
            .select()
            .single();

        return WaterRecordDto.fromSupabaseRow(
          Map<String, dynamic>.from(response),
        );
      },
    );
  }

  Future<WaterRecordDto> update(
    WaterRecordDto record, {
    required String userId,
  }) {
    return _database.run(
      operation: 'update',
      table: table,
      request: (query) async {
        final response = await query
            .update(record.toSupabaseUpdate(userId: userId))
            .eq('id', record.id)
            .eq('user_id', userId)
            .select()
            .single();

        return WaterRecordDto.fromSupabaseRow(
          Map<String, dynamic>.from(response),
        );
      },
    );
  }

  Future<WaterRecordDto> softDelete(
    WaterRecordDto record, {
    required String userId,
  }) {
    return update(record, userId: userId);
  }

  Future<List<WaterRecordDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) {
    return _database.run(
      operation: 'select',
      table: table,
      request: (query) async {
        var request = query.select().eq('user_id', userId);

        if (updatedAfter != null) {
          request = request.gt('updated_at', updatedAfter.toIso8601String());
        }

        final response = await request.order('updated_at');

        return response
            .map((row) => WaterRecordDto.fromSupabaseRow(row))
            .toList();
      },
    );
  }
}

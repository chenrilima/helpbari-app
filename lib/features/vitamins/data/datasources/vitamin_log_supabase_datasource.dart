import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/vitamin_log_dto.dart';

class VitaminLogSupabaseDatasource {
  const VitaminLogSupabaseDatasource(this._database);
  final SupabaseDatabase _database;
  Future<VitaminLogDto> upsert(VitaminLogDto value, {required String userId}) =>
      _database.run(
        operation: 'upsert',
        table: 'vitamin_logs',
        request: (query) async => VitaminLogDto.fromSupabaseRow(
          Map<String, dynamic>.from(
            await query
                .upsert(value.toSupabaseRow(userId: userId))
                .select()
                .single(),
          ),
        ),
      );
  Future<List<VitaminLogDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: 'vitamin_logs',
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      return (await request.order(
        'updated_at',
      )).map(VitaminLogDto.fromSupabaseRow).toList();
    },
  );
}

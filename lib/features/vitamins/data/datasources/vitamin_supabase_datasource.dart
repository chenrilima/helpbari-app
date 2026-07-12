import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/vitamin_dto.dart';

class VitaminSupabaseDatasource {
  const VitaminSupabaseDatasource(this._database);
  final SupabaseDatabase _database;
  Future<VitaminDto> upsert(VitaminDto value, {required String userId}) =>
      _database.run(
        operation: 'upsert',
        table: 'vitamins',
        request: (query) async => VitaminDto.fromSupabaseRow(
          Map<String, dynamic>.from(
            await query
                .upsert(value.toSupabaseRow(userId: userId))
                .select()
                .single(),
          ),
        ),
      );
  Future<List<VitaminDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: 'vitamins',
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
      )).map(VitaminDto.fromSupabaseRow).toList();
    },
  );
}

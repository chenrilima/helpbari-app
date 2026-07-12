import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/meal_dto.dart';

class MealSupabaseDatasource {
  const MealSupabaseDatasource(this._database);
  static const table = 'meals';
  final SupabaseDatabase _database;

  Future<MealDto> upsert(MealDto meal, {required String userId}) =>
      _database.run(
        operation: 'upsert',
        table: table,
        request: (query) async => MealDto.fromSupabaseRow(
          Map<String, dynamic>.from(
            await query
                .upsert(meal.toSupabaseRow(userId: userId))
                .select()
                .single(),
          ),
        ),
      );

  Future<List<MealDto>> pull({
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
      return rows.map(MealDto.fromSupabaseRow).toList();
    },
  );
}

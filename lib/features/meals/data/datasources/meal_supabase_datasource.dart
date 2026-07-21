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
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<MealDto>> pullPages({
    required String userId,
    DateTime? updatedAfter,
    int pageSize = 500,
  }) => _database
      .pullUpdatedPages(
        table: table,
        userId: userId,
        updatedAfter: updatedAfter,
        pageSize: pageSize,
      )
      .map((rows) => rows.map(MealDto.fromSupabaseRow).toList());
}

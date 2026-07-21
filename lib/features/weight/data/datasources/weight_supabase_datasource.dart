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
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<WeightRecordDto>> pullPages({
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
      .map((rows) => rows.map(WeightRecordDto.fromSupabaseRow).toList());
}

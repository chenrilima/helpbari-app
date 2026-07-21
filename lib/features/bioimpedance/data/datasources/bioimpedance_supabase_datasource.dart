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
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<BioimpedanceRecordDto>> pullPages({
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
      .map((rows) => rows.map(BioimpedanceRecordDto.fromSupabaseRow).toList());
}

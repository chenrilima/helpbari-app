import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/supabase/database/versioned_remote_datasource.dart';
import '../dtos/water_record_dto.dart';

class WaterSupabaseDatasource
    implements VersionedRemoteDatasource<WaterRecordDto> {
  const WaterSupabaseDatasource(this._database);

  static const table = 'water_records';

  final SupabaseDatabase _database;

  @override
  Future<WaterRecordDto> upsertVersioned(
    WaterRecordDto record, {
    required String userId,
    required int? baseRevision,
  }) async => WaterRecordDto.fromSupabaseRow(
    await _database.versionedUpsert(
      table: table,
      userId: userId,
      recordId: record.id,
      row: record.toSupabaseInsert(userId: userId),
      baseRevision: baseRevision,
    ),
  );

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
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<WaterRecordDto>> pullPages({
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
      .map((rows) => rows.map(WaterRecordDto.fromSupabaseRow).toList());
}

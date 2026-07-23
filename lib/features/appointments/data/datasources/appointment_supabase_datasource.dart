import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/supabase/database/versioned_remote_datasource.dart';
import '../dtos/appointment_dto.dart';

class AppointmentSupabaseDatasource
    implements VersionedRemoteDatasource<AppointmentDto> {
  const AppointmentSupabaseDatasource(this._database);
  static const table = 'appointments';
  final SupabaseDatabase _database;
  @override
  Future<AppointmentDto> upsertVersioned(
    AppointmentDto value, {
    required String userId,
    required int? baseRevision,
  }) async => AppointmentDto.fromSupabaseRow(
    await _database.versionedUpsert(
      table: table,
      userId: userId,
      recordId: value.id,
      row: value.toSupabaseRow(userId: userId),
      baseRevision: baseRevision,
    ),
  );
  Future<AppointmentDto> upsert(
    AppointmentDto value, {
    required String userId,
  }) => _database.run(
    operation: 'upsert',
    table: table,
    request: (query) async => AppointmentDto.fromSupabaseRow(
      Map<String, dynamic>.from(
        await query
            .upsert(value.toSupabaseRow(userId: userId))
            .select()
            .single(),
      ),
    ),
  );
  Future<List<AppointmentDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<AppointmentDto>> pullPages({
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
      .map((rows) => rows.map(AppointmentDto.fromSupabaseRow).toList());
}

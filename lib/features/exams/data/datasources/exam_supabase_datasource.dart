import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/supabase/database/versioned_remote_datasource.dart';
import '../dtos/exam_dto.dart';

class ExamSupabaseDatasource implements VersionedRemoteDatasource<ExamDto> {
  const ExamSupabaseDatasource(this._database);
  static const table = 'exams';
  final SupabaseDatabase _database;
  @override
  Future<ExamDto> upsertVersioned(
    ExamDto value, {
    required String userId,
    required int? baseRevision,
  }) async => ExamDto.fromSupabaseRow(
    await _database.versionedUpsert(
      table: table,
      userId: userId,
      recordId: value.id,
      row: value.toSupabaseRow(userId: userId),
      baseRevision: baseRevision,
    ),
  );
  Future<ExamDto> upsert(ExamDto value, {required String userId}) =>
      _database.run(
        operation: 'upsert',
        table: table,
        request: (query) async => ExamDto.fromSupabaseRow(
          Map<String, dynamic>.from(
            await query
                .upsert(value.toSupabaseRow(userId: userId))
                .select()
                .single(),
          ),
        ),
      );
  Future<List<ExamDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) async => [
    await for (final page in pullPages(
      userId: userId,
      updatedAfter: updatedAfter,
    ))
      ...page,
  ];

  Stream<List<ExamDto>> pullPages({
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
      .map((rows) => rows.map(ExamDto.fromSupabaseRow).toList());
}

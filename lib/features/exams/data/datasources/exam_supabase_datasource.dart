import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/exam_dto.dart';

class ExamSupabaseDatasource {
  const ExamSupabaseDatasource(this._database);
  static const table = 'exams';
  final SupabaseDatabase _database;
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
      return rows.map(ExamDto.fromSupabaseRow).toList();
    },
  );
}

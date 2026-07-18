import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/medical_exam_dto.dart';

class MedicalExamSupabaseDatasource {
  const MedicalExamSupabaseDatasource(this._database);

  static const examTable = 'medical_exams';
  static const resultTable = 'medical_exam_results';

  final SupabaseDatabase _database;

  Future<MedicalExamDto> upsert(
    MedicalExamDto dto, {
    required String userId,
  }) async {
    final examRow = await _database.run(
      operation: 'upsert',
      table: examTable,
      request: (query) async => Map<String, dynamic>.from(
        await query.upsert(dto.toSupabaseRow(userId: userId)).select().single(),
      ),
    );
    if (dto.results.isNotEmpty) {
      await _database.run(
        operation: 'upsert',
        table: resultTable,
        request: (query) => query.upsert(
          dto.results
              .map((item) => item.toSupabaseRow(userId: userId))
              .toList(growable: false),
        ),
      );
    }
    final remoteResults = await _database.run(
      operation: 'select',
      table: resultTable,
      request: (query) async =>
          (await query
                  .select()
                  .eq('user_id', userId)
                  .eq('medical_exam_id', dto.exam.id)
                  .order('sort_order'))
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false),
    );
    return MedicalExamDto.fromSupabaseRow(
      exam: examRow,
      results: remoteResults,
    );
  }

  Future<List<MedicalExamDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: examTable,
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      final examRows = (await request.order(
        'updated_at',
      )).map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
      final results = <MedicalExamDto>[];
      for (final exam in examRows) {
        final resultRows = await _database.run(
          operation: 'select',
          table: resultTable,
          request: (inner) async =>
              (await inner
                      .select()
                      .eq('user_id', userId)
                      .eq('medical_exam_id', exam['id'] as String)
                      .order('sort_order'))
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList(growable: false),
        );
        results.add(
          MedicalExamDto.fromSupabaseRow(exam: exam, results: resultRows),
        );
      }
      return results;
    },
  );
}

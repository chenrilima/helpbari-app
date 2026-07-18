import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/medical_consultation_dto.dart';

class MedicalConsultationSupabaseDatasource {
  const MedicalConsultationSupabaseDatasource(this._database);

  static const table = 'medical_consultations';
  static const examLinkTable = 'medical_consultation_exams';
  static const bodyLinkTable = 'medical_consultation_body_compositions';

  final SupabaseDatabase _database;

  Future<MedicalConsultationDto> upsert(
    MedicalConsultationDto dto, {
    required String userId,
  }) async {
    final row = await _database.run(
      operation: 'upsert',
      table: table,
      request: (query) async => Map<String, dynamic>.from(
        await query.upsert(dto.toSupabaseRow(userId: userId)).select().single(),
      ),
    );
    await _database.run(
      operation: 'delete',
      table: examLinkTable,
      request: (query) => query
          .delete()
          .eq('user_id', userId)
          .eq('medical_consultation_id', dto.consultation.id),
    );
    if (dto.consultation.relatedExamIds.isNotEmpty) {
      await _database.run(
        operation: 'insert',
        table: examLinkTable,
        request: (query) => query.insert(
          dto.consultation.relatedExamIds
              .map(
                (id) => {
                  'user_id': userId,
                  'medical_consultation_id': dto.consultation.id,
                  'medical_exam_id': id,
                },
              )
              .toList(growable: false),
        ),
      );
    }
    await _database.run(
      operation: 'delete',
      table: bodyLinkTable,
      request: (query) => query
          .delete()
          .eq('user_id', userId)
          .eq('medical_consultation_id', dto.consultation.id),
    );
    if (dto.consultation.relatedBodyCompositionIds.isNotEmpty) {
      await _database.run(
        operation: 'insert',
        table: bodyLinkTable,
        request: (query) => query.insert(
          dto.consultation.relatedBodyCompositionIds
              .map(
                (id) => {
                  'user_id': userId,
                  'medical_consultation_id': dto.consultation.id,
                  'bioimpedance_record_id': id,
                },
              )
              .toList(growable: false),
        ),
      );
    }
    final examLinks = await _selectIds(
      table: examLinkTable,
      userId: userId,
      consultationId: dto.consultation.id,
      field: 'medical_exam_id',
    );
    final bodyLinks = await _selectIds(
      table: bodyLinkTable,
      userId: userId,
      consultationId: dto.consultation.id,
      field: 'bioimpedance_record_id',
    );
    return MedicalConsultationDto.fromSupabaseRow(
      row,
      relatedExamIds: examLinks,
      relatedBodyCompositionIds: bodyLinks,
    );
  }

  Future<List<MedicalConsultationDto>> pull({
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
      final items = <MedicalConsultationDto>[];
      for (final item in rows) {
        final row = Map<String, dynamic>.from(item);
        final consultationId = row['id'] as String;
        final examLinks = await _selectIds(
          table: examLinkTable,
          userId: userId,
          consultationId: consultationId,
          field: 'medical_exam_id',
        );
        final bodyLinks = await _selectIds(
          table: bodyLinkTable,
          userId: userId,
          consultationId: consultationId,
          field: 'bioimpedance_record_id',
        );
        items.add(
          MedicalConsultationDto.fromSupabaseRow(
            row,
            relatedExamIds: examLinks,
            relatedBodyCompositionIds: bodyLinks,
          ),
        );
      }
      return items;
    },
  );

  Future<List<String>> _selectIds({
    required String table,
    required String userId,
    required String consultationId,
    required String field,
  }) => _database.run(
    operation: 'select',
    table: table,
    request: (query) async =>
        (await query
                .select(field)
                .eq('user_id', userId)
                .eq('medical_consultation_id', consultationId))
            .map((row) => row[field] as String)
            .toList(growable: false),
  );
}

import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/medication_dto.dart';

class MedicationSupabaseDatasource {
  const MedicationSupabaseDatasource(this._database);
  final SupabaseDatabase _database;
  Future<MedicationDto> upsert(MedicationDto value, {required String userId}) =>
      _database.run(
        operation: 'upsert',
        table: 'medications',
        request: (q) async => MedicationDto.fromSupabaseRow(
          Map<String, dynamic>.from(
            await q
                .upsert(value.toSupabaseRow(userId: userId))
                .select()
                .single(),
          ),
        ),
      );
  Future<List<MedicationDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: 'medications',
    request: (q) async {
      var request = q.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      return (await request.order(
        'updated_at',
      )).map(MedicationDto.fromSupabaseRow).toList();
    },
  );
}

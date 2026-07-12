import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/appointment_dto.dart';

class AppointmentSupabaseDatasource {
  const AppointmentSupabaseDatasource(this._database);
  static const table = 'appointments';
  final SupabaseDatabase _database;
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
      return rows.map(AppointmentDto.fromSupabaseRow).toList();
    },
  );
}

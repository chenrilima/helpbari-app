import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/profile_dto.dart';

abstract interface class ProfileRemoteDatasource {
  Future<ProfileDto> upsert(ProfileDto value, String userId);
  Future<List<ProfileDto>> pull(String userId, DateTime? updatedAfter);
}

class ProfileSupabaseDatasource implements ProfileRemoteDatasource {
  const ProfileSupabaseDatasource(this._database);
  static const table = 'profiles';
  final SupabaseDatabase _database;

  @override
  Future<ProfileDto> upsert(ProfileDto value, String userId) => _database.run(
    operation: 'upsert',
    table: table,
    request: (query) async => ProfileDto.fromSupabase(
      Map<String, dynamic>.from(
        await query
            .upsert(value.toSupabase(userId), onConflict: 'user_id')
            .select()
            .single(),
      ),
    ),
  );

  @override
  Future<List<ProfileDto>> pull(String userId, DateTime? updatedAfter) =>
      _database.run(
        operation: 'select',
        table: table,
        request: (query) async {
          var request = query.select().eq('user_id', userId);
          if (updatedAfter != null) {
            request = request.gt('updated_at', updatedAfter.toIso8601String());
          }
          return (await request.order(
            'updated_at',
          )).map(ProfileDto.fromSupabase).toList();
        },
      );
}

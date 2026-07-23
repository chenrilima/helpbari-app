import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/onboarding_progress_dto.dart';

abstract interface class OnboardingProgressRemoteDatasource {
  Future<OnboardingProgressDto> upsert(OnboardingProgressDto value);
  Future<List<OnboardingProgressDto>> pull(
    String userId,
    DateTime? updatedAfter,
  );
}

final class OnboardingProgressSupabaseDatasource
    implements OnboardingProgressRemoteDatasource {
  const OnboardingProgressSupabaseDatasource(this._database);
  static const table = 'onboarding_states';
  final SupabaseDatabase _database;

  @override
  Future<OnboardingProgressDto> upsert(OnboardingProgressDto value) =>
      _database.run(
        operation: 'upsert',
        table: table,
        request: (query) async => OnboardingProgressDto.fromSupabase(
          Map<String, dynamic>.from(
            await query
                .upsert(value.toSupabase(), onConflict: 'user_id')
                .select()
                .single(),
          ),
        ),
      );

  @override
  Future<List<OnboardingProgressDto>> pull(
    String userId,
    DateTime? updatedAfter,
  ) => _database.run(
    operation: 'select',
    table: table,
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt('updated_at', updatedAfter.toIso8601String());
      }
      return (await request.order(
        'updated_at',
      )).map(OnboardingProgressDto.fromSupabase).toList();
    },
  );
}

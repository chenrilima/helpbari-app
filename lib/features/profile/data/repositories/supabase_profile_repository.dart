import 'package:helpbari/features/profile/domain/entities/profile.dart';

import '../../../../core/failures/failures.dart';
import '../../domain/repositories/repositories.dart';

class SupabaseProfileRepository implements ProfileRepository {
  @override
  Future<void> deleteProfile(Profile profile) async {
    throw const UnexpectedFailure(
      message: 'Exclusão de perfil no Supabase ainda não implementada.',
      code: 'profile_delete_not_implemented',
    ).toException();
  }

  @override
  Future<Profile?> getProfile() async {
    throw const UnexpectedFailure(
      message: 'Busca de perfil no Supabase ainda não implementada.',
      code: 'profile_get_not_implemented',
    ).toException();
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    throw const UnexpectedFailure(
      message: 'Criação de perfil no Supabase ainda não implementada.',
      code: 'profile_save_not_implemented',
    ).toException();
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    throw const UnexpectedFailure(
      message: 'Atualização de perfil no Supabase ainda não implementada.',
      code: 'profile_update_not_implemented',
    ).toException();
  }
}

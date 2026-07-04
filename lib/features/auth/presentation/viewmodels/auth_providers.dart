import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpbari/features/auth/data/repositories/supabase_auth_repository.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../states/auth_state.dart';
import 'auth_view_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

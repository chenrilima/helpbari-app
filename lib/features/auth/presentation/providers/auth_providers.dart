import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/interceptors/supabase_interceptors_provider.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/datasources/supabase_auth_datasource.dart';
import '../../data/datasources/unconfigured_auth_datasource.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/use_cases.dart';
import '../states/auth_state.dart';
import '../viewmodels/auth_view_model.dart';

final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    return const UnconfiguredAuthDatasource();
  }

  return SupabaseAuthDatasource(
    client: client,
    interceptorRunner: ref.watch(supabaseInterceptorRunnerProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(authDatasourceProvider));
});

final authUseCasesProvider = Provider<AuthUseCases>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return AuthUseCases(
    getCurrentUser: GetCurrentAuthUserUseCase(repository),
    watchAuthState: WatchAuthStateUseCase(repository),
    signInWithEmailAndPassword: SignInWithEmailAndPasswordUseCase(repository),
    signUpWithEmailAndPassword: SignUpWithEmailAndPasswordUseCase(repository),
    signInWithGoogle: SignInWithGoogleUseCase(repository),
    signOut: SignOutUseCase(repository),
  );
});

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authUseCasesProvider).watchAuthState();
});

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

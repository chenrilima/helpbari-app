import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../interceptors/supabase_interceptors_provider.dart';
import '../supabase_client_provider.dart';
import 'supabase_storage_service.dart';

final supabaseStorageProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService(
    client: ref.watch(requiredSupabaseClientProvider),
    interceptorRunner: ref.watch(supabaseInterceptorRunnerProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../interceptors/supabase_interceptors_provider.dart';
import '../supabase_client_provider.dart';
import 'supabase_database.dart';

final supabaseDatabaseProvider = Provider<SupabaseDatabase>((ref) {
  return SupabaseDatabase(
    client: ref.watch(requiredSupabaseClientProvider),
    interceptorRunner: ref.watch(supabaseInterceptorRunnerProvider),
  );
});

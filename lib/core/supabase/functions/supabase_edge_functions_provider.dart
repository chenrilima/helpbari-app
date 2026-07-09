import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../interceptors/supabase_interceptors_provider.dart';
import '../supabase_client_provider.dart';
import 'supabase_edge_functions.dart';

final supabaseEdgeFunctionsProvider = Provider<SupabaseEdgeFunctions>((ref) {
  return SupabaseEdgeFunctions(
    client: ref.watch(requiredSupabaseClientProvider),
    interceptorRunner: ref.watch(supabaseInterceptorRunnerProvider),
  );
});

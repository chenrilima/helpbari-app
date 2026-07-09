import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase_client_provider.dart';
import 'auth_supabase_interceptor.dart';
import 'logging_supabase_interceptor.dart';
import 'supabase_request_interceptor.dart';

final supabaseInterceptorsProvider = Provider<List<SupabaseRequestInterceptor>>(
  (ref) {
    final client = ref.watch(supabaseClientProvider);

    return [
      const LoggingSupabaseInterceptor(),
      AuthSupabaseInterceptor(
        currentUserId: () => client?.auth.currentUser?.id,
      ),
    ];
  },
);

final supabaseInterceptorRunnerProvider = Provider<SupabaseInterceptorRunner>((
  ref,
) {
  return SupabaseInterceptorRunner(ref.watch(supabaseInterceptorsProvider));
});

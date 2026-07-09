import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase_client_provider.dart';
import 'supabase_realtime_service.dart';

final supabaseRealtimeProvider = Provider<SupabaseRealtimeService>((ref) {
  return SupabaseRealtimeService(ref.watch(requiredSupabaseClientProvider));
});

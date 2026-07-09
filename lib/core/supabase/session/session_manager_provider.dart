import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase_client_provider.dart';
import 'session_manager.dart';
import 'supabase_session_manager.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SupabaseSessionManager(ref.watch(supabaseClientProvider));
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionManagerProvider).currentUserId;
});

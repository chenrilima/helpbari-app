import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../failures/failures.dart';
import 'supabase_config.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isInitialized) return null;

  return Supabase.instance.client;
});

final requiredSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    throw const NetworkFailure(
      message: 'Supabase não está configurado para este ambiente.',
      code: 'supabase_not_configured',
    ).toException();
  }

  return client;
});

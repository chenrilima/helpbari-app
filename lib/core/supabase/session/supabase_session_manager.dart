import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../features/auth/data/mappers/auth_user_mapper.dart';
import '../../../features/auth/domain/entities/auth_user.dart';
import 'session_manager.dart';

class SupabaseSessionManager implements SessionManager {
  const SupabaseSessionManager(this._client);

  final SupabaseClient? _client;

  @override
  AuthUser? get currentUser => _client?.auth.currentUser?.toDomain();

  @override
  Session? get currentSession => _client?.auth.currentSession;

  @override
  String? get currentUserId => currentUser?.id;

  @override
  bool get isAuthenticated => currentSession != null;

  @override
  Stream<AuthUser?> get authStateChanges {
    final client = _client;

    if (client == null) return const Stream.empty();

    return client.auth.onAuthStateChange.map((event) {
      return event.session?.user.toDomain();
    });
  }
}

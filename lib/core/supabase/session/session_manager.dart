import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../features/auth/domain/entities/auth_user.dart';

abstract interface class SessionManager {
  AuthUser? get currentUser;

  Session? get currentSession;

  String? get currentUserId;

  bool get isAuthenticated;

  Stream<AuthUser?> get authStateChanges;
}

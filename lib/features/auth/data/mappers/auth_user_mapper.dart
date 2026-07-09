import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/auth_user.dart';

extension AuthUserMapper on supabase.User {
  AuthUser toDomain() {
    return AuthUser(id: id, email: email);
  }
}

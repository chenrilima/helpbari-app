import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepositoryBackend { fake, local, supabase }

final repositoryBackendProvider = Provider<RepositoryBackend>((ref) {
  return RepositoryBackend.local;
});

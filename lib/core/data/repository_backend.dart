import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepositoryBackend { local, supabase }

final repositoryBackendProvider = Provider<RepositoryBackend>((ref) {
  return RepositoryBackend.local;
});

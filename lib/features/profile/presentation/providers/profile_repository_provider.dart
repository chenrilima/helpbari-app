import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_profile_repository.dart';
import '../../domain/repositories/repositories.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});

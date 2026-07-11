import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import 'profile_repository_provider.dart';

final profileUseCasesProvider = Provider<ProfileUseCases>((ref) {
  final repository = ref.watch(profileRepositoryProvider);

  return ProfileUseCases(
    getProfile: GetProfileUseCase(repository),
    saveProfile: SaveProfileUseCase(repository),
    updateProfile: UpdateProfileUseCase(repository),
    deleteProfile: DeleteProfileUseCase(repository),
  );
});

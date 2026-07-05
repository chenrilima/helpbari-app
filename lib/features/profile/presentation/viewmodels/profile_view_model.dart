import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/use_cases.dart';
import '../providers/profile_use_case_providers.dart';
import '../states/profile_state.dart';

class ProfileViewModel extends Notifier<ProfileState> {
  late final ProfileUseCases _useCases;

  @override
  ProfileState build() {
    _useCases = ref.read(profileUseCasesProvider);

    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _useCases.getProfile();

      state = state.copyWith(profile: profile, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

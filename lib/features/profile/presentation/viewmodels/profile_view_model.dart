import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../models/create_profile_form.dart';
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

  Future<void> createProfile(CreateProfileForm form) async {
    state = state.copyWith(isLoading: true);

    try {
      final height = Height.create(form.height);
      final initialWeight = Weight.create(form.initialWeight);
      final targetWeight = form.targetWeight == null
          ? null
          : Weight.create(form.targetWeight!);

      if (height == null || initialWeight == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Dados inválidos para criar o perfil.',
        );
        return;
      }

      final profile = Profile(
        id: 'local-profile',
        name: form.name,
        email: form.email,
        birthDate: AppDate(form.birthDate),
        height: height,
        initialWeight: initialWeight,
        targetWeight: targetWeight,
        surgeryDate: AppDate(form.surgeryDate),
        surgeryType: form.surgeryType,
        createdAt: AppDate(DateTime.now()),
      );

      await _useCases.saveProfile(profile);

      state = state.copyWith(profile: profile, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

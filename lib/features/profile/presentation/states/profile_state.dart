import '../../domain/entities/entities.dart';

class ProfileState {
  const ProfileState({this.profile, this.isLoading = false, this.errorMessage});

  final Profile? profile;
  final bool isLoading;
  final String? errorMessage;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

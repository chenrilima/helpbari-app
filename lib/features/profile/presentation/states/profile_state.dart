import '../../domain/entities/entities.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final Profile? profile;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: clearProfile ? null : profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

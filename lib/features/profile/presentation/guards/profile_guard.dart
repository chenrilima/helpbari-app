import '../../../profile/domain/entities/entities.dart';
import '../../../../app/router/app_routes.dart';
import '../states/profile_state.dart';

class ProfileGuard {
  const ProfileGuard._();

  static bool isProfileCompleted(Profile? profile) {
    return profile != null;
  }

  static String? redirect({
    required String location,
    required ProfileState state,
  }) {
    if (!state.hasLoaded || state.isLoading || state.errorMessage != null) {
      return null;
    }
    final completing = location == AppRoutes.completeProfile;
    if (state.profile == null) {
      return completing ? null : AppRoutes.onboarding;
    }
    return null;
  }
}

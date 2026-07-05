import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/profile_state.dart';
import '../viewmodels/profile_view_model.dart';

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);

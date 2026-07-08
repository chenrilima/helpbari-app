import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/setting_state.dart';
import '../viewmodels/setting_view_model.dart';

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);

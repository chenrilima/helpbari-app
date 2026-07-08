import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/progress_state.dart';
import '../viewmodels/progress_view_model.dart';

final progressViewModelProvider =
    NotifierProvider<ProgressViewModel, ProgressState>(ProgressViewModel.new);

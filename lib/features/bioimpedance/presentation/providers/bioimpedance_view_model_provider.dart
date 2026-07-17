import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/bioimpedance_state.dart';
import '../viewmodels/bioimpedance_view_model.dart';

final bioimpedanceViewModelProvider =
    NotifierProvider<BioimpedanceViewModel, BioimpedanceState>(
      BioimpedanceViewModel.new,
    );

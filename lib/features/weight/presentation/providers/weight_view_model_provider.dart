import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/weight_state.dart';
import '../viewmodels/weight_view_model.dart';

final weightViewModelProvider = NotifierProvider<WeightViewModel, WeightState>(
  WeightViewModel.new,
);

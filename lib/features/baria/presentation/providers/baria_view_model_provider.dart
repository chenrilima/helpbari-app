import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/baria_state.dart';
import '../state/baria_view_model.dart';

final bariaViewModelProvider = NotifierProvider<BariaViewModel, BariaState>(
  BariaViewModel.new,
);

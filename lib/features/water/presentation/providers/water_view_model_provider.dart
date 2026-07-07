import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/water_state.dart';
import '../viewmodels/water_view_model.dart';

final waterViewModelProvider = NotifierProvider<WaterViewModel, WaterState>(
  WaterViewModel.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/vitamin_state.dart';
import '../viewmodels/vitamin_view_model.dart';

final vitaminViewModelProvider =
    NotifierProvider<VitaminViewModel, VitaminState>(VitaminViewModel.new);

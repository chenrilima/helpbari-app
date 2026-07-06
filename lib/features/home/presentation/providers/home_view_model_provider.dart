import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/home_state.dart';
import '../viewmodels/home_view_model.dart';

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

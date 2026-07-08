import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/meal_state.dart';
import '../viewmodels/meal_view_model.dart';

final mealViewModelProvider = NotifierProvider<MealViewModel, MealState>(
  MealViewModel.new,
);

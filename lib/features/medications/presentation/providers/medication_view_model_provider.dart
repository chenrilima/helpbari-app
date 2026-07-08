import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/medication_state.dart';
import '../viewmodels/medication_view_model.dart';

final medicationViewModelProvider =
    NotifierProvider<MedicationViewModel, MedicationState>(
      MedicationViewModel.new,
    );

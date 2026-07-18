import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/medical_consultation_state.dart';
import '../viewmodels/medical_consultation_view_model.dart';

final medicalConsultationViewModelProvider =
    NotifierProvider<MedicalConsultationViewModel, MedicalConsultationState>(
      MedicalConsultationViewModel.new,
    );

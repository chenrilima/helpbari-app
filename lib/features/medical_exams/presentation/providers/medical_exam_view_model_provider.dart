import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/medical_exam_state.dart';
import '../viewmodels/medical_exam_view_model.dart';

final medicalExamViewModelProvider =
    NotifierProvider<MedicalExamViewModel, MedicalExamState>(
      MedicalExamViewModel.new,
    );
